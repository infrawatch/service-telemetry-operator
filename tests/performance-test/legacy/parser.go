/*
* parser    ---    Paul Leimer    ---    19 July 2019
* Reads in and builds test configuration objects
 */

package main

import (
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"strconv"
	"time"
)

var ipaddr string = "127.0.0.1"
var args []string = []string{}

// test type holds test configuration data
type test struct {
	Metadata struct {
		Name string `yaml:"name"`
	}
	Spec struct {
		Valuelists uint64   `yaml:"value-lists"`
		Hosts      uint64   `yaml:"hosts"`
		Plugins    uint64   `yaml:"plugins"`
		Interval   uint64   `yaml:"interval"`
		Length     uint64   `yaml:"length"`
		Queries    []string `yaml:"queries"`
	}
}

type Parser struct {
	tests []test
}

//LoadTests loads in a test onfiguration file for parsing
func (p *Parser) LoadTests(fn string) error {
	yamlFile, err := ioutil.ReadFile(fn)
	if err != nil {

		return err
	}

	err = yaml.UnmarshalStrict(yamlFile, &p.tests)
	if err != nil {
		return err
	}
	return nil
}

// ArgStrings generates the correct parameters for a unit test from the test configuration
func (p Parser) ArgStrings(t test) []string {
	retArgs := []string{}

	if t.Spec.Valuelists != 0 {
		retArgs = append(retArgs, "-n")
		retArgs = append(retArgs, strconv.FormatUint(t.Spec.Valuelists, 10))
	}

	if t.Spec.Hosts != 0 {
		retArgs = append(retArgs, "-H")
		retArgs = append(retArgs, strconv.FormatUint(t.Spec.Hosts, 10))
	}

	if t.Spec.Plugins != 0 {
		retArgs = append(retArgs, "-p")
		retArgs = append(retArgs, strconv.FormatUint(t.Spec.Plugins, 10))
	}

	if t.Spec.Interval != 0 {
		retArgs = append(retArgs, "-i")
		retArgs = append(retArgs, strconv.FormatUint(t.Spec.Interval, 10))
	}

	//using default collectd network port
	retArgs = append(retArgs, []string{"-d", ipaddr, "-l", strconv.FormatUint(t.Spec.Length, 10)}...)

	return retArgs
}

// GetTimes returns time duration for test as time objects in UTC.
// Calculates times relative to now
func (p Parser) GetTimes(testIndex int) (time.Time, time.Time) {
	test := p.tests[testIndex]
	start := time.Now()
	end := start.Add(time.Second * time.Duration(test.Spec.Length))

	return start, end
}

// Tests provides access to a list of test configuration objects
func (p Parser) Tests() []test {
	return p.tests
}
