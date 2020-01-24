package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strconv"
	"time"
)

type PerformanceTest struct {
	p     *Parser
	err   error
	start time.Time
	end   time.Time
}

// Err allows for better error handling by blocking class functionality if
// an error occurs within a performance test. This minimizes the amount
// of error checks necessary in code
func (pt *PerformanceTest) Err() error {
	return pt.err
}

//InitParser creates a parser object with the test config file loaded into it
func (pt *PerformanceTest) InitParser() {
	if pt.err != nil {
		return
	}
	pt.p = new(Parser)
	pt.err = pt.p.LoadTests("/performance-test/config/test-configs.yml")
}

//ExecTest runs a performance test configuration
func (pt *PerformanceTest) ExecTest(index int) error {
	test := pt.p.Tests()[index]
	log.Print("Running test of length " + strconv.FormatUint(test.Spec.Length, 10) + "s")

	args := pt.p.ArgStrings(test)
	cmd := exec.Command("/performance-test/exec/launch-test.sh", args...)
	cmd.Stderr = cmd.Stdout
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	cmd.Start()

	scanner := bufio.NewScanner(cmdReader)
	for scanner.Scan() {
		log.Print(scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "reading standard input:", err)
	}

	log.Print("Cooling down for 30 seconds")
	time.Sleep(time.Second * time.Duration(30))

	return err
}

//Run executes a sequence of performance tests and generates dashboards and graphs for each in grafana
func (pt *PerformanceTest) Run() {
	if pt.err != nil {
		return
	}

	for i, test := range pt.p.Tests() {

		pt.start, pt.end = pt.p.GetTimes(i)
		// BUG? These values depend on test pod startup time
		pt.start = pt.start.Add(time.Second * -60) // Add lead time to the dashboard
		pt.end = pt.end.Add(time.Second * 60)      // Add cool-down time to the dashboard

		log.Printf("Generating dashboard '%s' from %s to %s", test.Metadata.Name, pt.start, pt.end)

		pt.err = pt.ExecTest(i)
	}
}

func main() {
	pt := new(PerformanceTest)
	pt.InitParser()
	pt.Run()

	if pt.Err() != nil {
		log.Fatal(pt.Err())
	}
}
