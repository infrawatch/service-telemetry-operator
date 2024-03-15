# service-telemetry-operator CI playbooks

The playbooks in this directory are used by zuul jobs, which are defined in ../.zuul.yaml.

## Job descriptions

### PR jobs

There are 6 jobs run on every PR that is targeting `master`.
These are reported under the `rdoproject.org/github-check` check.

Two scenarios run:
- `local_build`, which builds the STF images and deploys by creating a STF object.
- `local_build-index_deploy`, which builds the images and does an index-based deployment

Each of these scenarios run across the following OCP versions:
- 4.12
- 4.13
- 4.14

### Periodic jobs

The `nightly_bundles` jobs are run nightly. These jobs deploy STF using the nightly builds published to quay.io.
The same three versions of OCP are used.

## Job hierarchy

The jobs in this repo have two base jobs:

- `stf-base-2node`
- `stf-base`

These two base jobs are split according to purpose: infrastructure provisioning and STF deployment.

`stf-base-2node` inherits from jobs defined in [ci-framework](http://github.com/openstack-k8s-operators/ci-framework), [rdo-jobs](https://review.rdoproject.org/cgit/rdo-jobs/) and [rdo/config](https://review.rdoproject.org/cgit/config/) repos.
This job configures the hosts used for running the jobs.
It is expected that `stf-base-2node` should not be modified unless there are changes to the upstream jobs.

`stf-base` inherits from `stf-base-2node`, and defines the stf-specific parts of the jobs (prepare hosts, build STF images, deploy STF, test STF).

These jobs are [abstract](https://zuul-ci.org/docs/zuul/latest/config/job.html#attr-job.abstract) and cannot be run directly, however, they contain the plumbing that allows the deployment scenario and OCP version to be configured.

The scenario (`nightly_bundles`, `local_build`, `local_build-index_deploy`) is selected by passing a `scenario` [var to the job](https://zuul-ci.org/docs/zuul/latest/config/job.html#attr-job.vars).
The OCP version is selected by changing the nodeset that is use in the job.

The jobs are named to describe the combination of scenario and OCP version that is used in the job.
The naming convention is `stf-crc-ocp_<version>-<scenario> e.g. `stf-crc-ocp_413-local_build`

## OCP version selection

The OCP version selection is done by specifying the `nodeset` to be used by the job.
The `nodesets` are defined in `.zuul.yaml`. Each nodeset corresponds to a different version of OCP.
Each nodeset contains two hosts: `crc` and `controller`.
All ansible playbooks are run against `controller`.

The rest of this section provides further detail on the OCP version selection, and how it relates to CRC and the deployment topology.

The nodesets select the hosts based on labels in zuul.
The labels available in zuul are shown on the [RDO Zuul labels tab](https://review.rdoproject.org/zuul/labels).

The labels used for the nodesets are `coreos-crc-extracted-<crc_version>-<size>`.
The “extracted” CRC describes the way that the job deploys and interacts with CRC.

Usually, CRC is run using the `crc start` command, which created a VM on your host which runs the OCP cloud.
In Zuul, the provisioned hosts are also virtual machines, so running `crc start` would result in a VM in a VM. This nested virtualisation causes some performance issues.

The `extracted` deployment try to address the performance issues associated with nested virtualisation. The infrastructure is more complicated than nested.
The `coreos-crc-extracted-...` labels provide a VM with an extracted CRC VM image, so that the CRC VM can be booted directly by the cloud provider. The `crc` VM is not accessed directly, but via a second `controller` VM, on which tests are run. The `stf-base-2node` job includes a network configuration to make sure the controller can communicate with the OCP deployment in CRC. All ansible playbooks should be run against `controller`. The `stf-base-2node` job is a common parent to all the jobs in the repo, and should rarely need an update.

The name of each nodeset corresponds to the version of OCP that is deployed by the CRC image.

## Adding new jobs

If a new job needs to be added, it should inherit from `stf-base` ( or one of its child-jobs) which includes common tasks for setting up STF. The new jobs should have minimal configuration lines; either the `scenario` var is passed, which selects a vars file for stf-run-ci, to change its configuration, or the nodeset should be updated, which selects the OCP version.

Below are examples of how to add a job. Take note of how the `scenario` var and the `nodeset` is passed.

    - job:
        name: stf-crc-nightly_bundles
        parent: stf-base
        abstract: true
        description: |
          Example of a job that extends the `stf-base` job, and passes the `nightly_bundles` scenario var. This job does NOT have a nodeset defined so it must be abstract.
        vars:
          scenario: "nightly_bundles"

OR

    - job:
        name: stf-crc-ocp_414-nightly_bundles
        parent: stf-crc-nightly_bundles
        description: |
          Example of a job defining a nodeset to be used.
          Since this job derives from a job with a scenario, it can be run directly.
        nodeset: stf-crc_extracted-ocp414

All non-abstract jobs inheriting from `stf-base` must pass a `scenario` var to work correctly. There is no default value for the `scenario`.
All non-abstract jobs defined in this repo must have a `nodeset` to run correctly. Specifically, the nodeset must include nodes called `controller` and `crc`. This requirements comes from the `stf-base-2node` job.

Once a new job is defined, it should be added to a project or to the `stf-crc-jobs` [template](https://zuul-ci.org/docs/zuul/latest/config/project.html#project-template) in `.zuul.yaml`.
Any job added to a project is run only against changes to that project.
Any job added to the `stf-crc-jobs` project template is run in the other repos across the infrawatch org.

## Troubleshooting

## FAQ

### How does Zuul work across branches?
Each branch has its own zuul configuration. The configuration for a particular branch lives on that branch.
To run jobs on a branch, the `.zuul.yaml` file needs to exist on that branch.

### How does Zuul decide which branches to check out?

- For the repo-in-test, zuul checks out the dev branch.
- For all other required repos, zuul checks out the branch with the same name as the target (usually master, sometimes stable*)
- If  `branch-override` option is specified in the job definition, then that branch is checked out instead of the default.
- When you use `Depends-On`, it checks out the branch in the referenced PR/changeset.

### How do I test dependant patches?
If you're working on a a change that involves PRs to multiple repos (which are tested by Zuul), you can add a `Depends-On: <url of PR>` line to the PR description of your change.

You can use `Depends-On` to reference a change in any repo that zuul knows about (i.e. included in `project.yaml` in RDO in this case).

### How do I add Zuul to a new repo?
The Zuul instance we use is hosted by RDO. In order for jobs to be run on a new repo, the following criteria must be met:
- The `softwarefactory-project-zuul` github app must also be added to the organisation (this is already done for infrawatch).
- The repo must be configured in [rdo/config](https://review.rdoproject.org/cgit/config/tree/zuul/rdo.yaml). An example of adding a repo is (here)[https://review.rdoproject.org/r/c/config/+/51666).
- The `softwarefactory-project-zuul` app must have repository access configured for the repo you want to add. This setting can be found in organisation/infrawatch -> settings -> Github Apps.

### How do I configure job triggers?
In Zuul, jobs themselves don't have triggers. Triggers are configure per-pipeline.
Each job needs to be added to a pipeline to run.

RDO Zuul defines the (pipelines that we can use)[https://review.rdoproject.org/cgit/config/tree/zuul.d/pipelines.yaml].
