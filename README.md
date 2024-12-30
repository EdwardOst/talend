# Talend

Talend devops utilities for installation of Talend servers including TAC, jobserver, runtime, nexus, amc, and CI.


### Configuration

Binary files are downloaded from Talend web site using two configuration files.

* talend.manifest - list of urls to download
* talend.credentials - talend userid and password.

`talend.credentials` is a property file and the properties must occur in the order specified.  The equals sign is the separator.
No whitespace, comments, or blank lines are allowed.


### Commands

Source the `talend-init` script and the commands below will become available.

  **talend** - Base command invokes talend_config by default to intialize configuration shell variables.

  **setup** - Download the necessary talend binaries to a persistent volume.

  **tac** - install and configure tac server

  **jobserver** - install and configure job server

  **nexus** - install and configure nexus server

  **runtime** - install and configure esb runtime

  **amc** - install and configure amc


### Usage

Only local variables are used for configuration.  They are initialized by the config function and are only scoped within that function.

All  commands use function chaining to just call whatever arguments are passed as subcommands.  So subsequent subcommands execute within the same function scope.

Local shell variables are initialized to any prior existing value, so they can be overridden by simply setting them before calling the config function.


### Example

````bash
source talend-init
talend setup
talend tac nexus jobserver
````

By convention, all commands support function chaining.  So they can be concatenated in a single command to execute in a common context.

````bash
talend setup tac nexus jobserver
````

By convention, config only sets variables which do not already have a prior value.  To override a config setting set a global shell variable
of the same name and it will be picked up each time the config initializes the context.

````bash
source talend-init
talend_volume="my_talend_volume"
talend setup
````

While a global override can be useful when there is only a single instance, if multiple instances have to run concurrently it is better to encapsulate each
in its own configuration function.  The configuration function can delegate the bulk of the configuration to the base config and override just targeted properties.
Multiple named instances can be created in this manner, each identified by its own configuration function.   The init only needs to be called once.

````bash
source talend-init

my_talend() {
  talend_volume="my_talend_volume"
  talend "$@"
}
my_talend setup tac

````
