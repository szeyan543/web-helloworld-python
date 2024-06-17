# web-helloworld-python

![License](https://img.shields.io/github/license/open-horizon-services/web-helloworld-python)
![Architecture](https://img.shields.io/badge/architecture-x86,arm64-green)
![Contributors](https://img.shields.io/github/contributors/open-horizon-services/web-helloworld-python.svg)

This Open Horizon service demonstrates a simple HTTP server written in Python. The server responds with a "Hello, World!" message on port 8000. To check the "Hello, World!" message in your web browser, navigate to http://localhost:8000/.

## Prerequisites

To ensure the successful installation and operation of the Open Horizon service, the following prerequisites must be met:


**Open Horizon Management Hub:** To publish this service and register your edge node, you must either [install the Open Horizon Management Hub](https://open-horizon.github.io/quick-start) or have access to an existing hub. You may also choose a downstream commercial distribution like IBM's Edge Application Manager. If you'd like to use the Open Horizon community hub, you may [apply for a temporary account](https://wiki.lfedge.org/display/LE/Open+Horizon+Management+Hub+Developer+Instance) at the Open Horizon community hub, where credentials will be provided.

**Edge Node:**You will need an x86 computer running Linux or macOS, or an ARM64 device such as a Raspberry Pi running Raspberry Pi OS or Ubuntu. The `anax` agent software must be installed on your edge node. This software facilitates communication with the Management Hub and manages the deployment of services.

**Optional Utilities:** Depending on your operating system, you may use:
  - `brew` on macOS
  - `apt-get` on Ubuntu or Raspberry Pi OS
  - `yum` on Fedora
  
  These commands can install `gcc`, `make`, `git`, `jq`, `curl`, and `net-tools`. These utilities are not strictly required but are highly recommended for successful deployment and troubleshooting.


## Installation

1. **Clone the repository:**
    Clone the `web-helloworld-python` GitHub repo from a terminal prompt on the edge node and enter the folder where the artifacts were copied.

   ```shell
   git clone https://github.com/open-horizon-services/web-helloworld-python.git
   cd web-helloworld-python
    ```

2. **Edit Makefile:**
    Adjust the variables at the top of the Makefile as needed, including your Docker ID and unique names for your service and pattern.

    Run `make clean` to confirm that the "make" utility is installed and workin

    Confirm that you have the Open Horizon agent installed by using the CLI to check the version:

    ``` shell
     hzn version
     ```

    It should return values for both the CLI and the Agent (actual version numbers may vary from those shown):

    ``` text
    Horizon CLI version: 2.31.0-1540
    Horizon Agent version: 2.31.0-1540
    ```

    If it returns "Command not found", then the Open Horizon agent is not installed.

    If it returns a version for the CLI but not the agent, then the agent is installed but not running.  You may run it with `systemctl horizon start` on Linux or `horizon-container start` on macOS.

    Check that the agent is in an unconfigured state, and that it can communicate with a hub.  If you have the `jq` utility installed, run `hzn node list | jq '.configstate.state'` and check that the value returned is "unconfigured".  If not, running `make agent-stop` or `hzn unregister -f` will put the agent in an unconfigured state.  Run `hzn node list | jq '.configuration'` and check that the JSON returned shows values for the "exchange_version" property, as well as the "exchange_api" and "mms_api" properties showing URLs.  If those do not, then the agent is not configured to communicate with a hub.  If you do not have `jq` installed, run `hzn node list` and eyeball the sections mentioned above.

    NOTE: If "exchange_version" is showing an empty value, you will not be able to publish and run the service.  The only fix found to this condition thus far is to re-install the agent using these instructions:

    ```shell
    hzn unregister -f # to ensure that the node is unregistered
    systemctl horizon stop # for Linux, or "horizon-container stop" on macOS
    export HZN_ORG_ID=myorg   # or whatever you customized it to
    export HZN_EXCHANGE_USER_AUTH=admin:<admin-pw>   # use the pw deploy-mgmt-hub.sh displayed
    export HZN_FSS_CSSURL=http://<mgmt-hub-ip>:9443/
    curl -sSL https://github.com/open-horizon/anax/releases/latest/download/agent-install.sh | bash -s -- -i anax: -k css: -c css: -p IBM/pattern-ibm.helloworld -w '*' -T 120
    ```

## Usage

### Using the Service Outside of Open Horizon

If you wish to use this service locally for development or testing purposes without integrating with the Open Horizon ecosystem, follow these commands:

```shell
make build
# This command builds the Docker container from your Dockerfile, preparing it for local execution.

make run
# This runs the container locally. It will start the service on the designated port, making it accessible on your machine.

# Test the service
make test
# This command is used to run any predefined tests that check the functionality of the service. It ensures that the service responds correctly.

make stop
# Stops the running Docker container. Use this command when you are done with testing or running the service locally.
```

### Using the Service Inside Open Horizon
 
 ```shell
docker login
# Log in to your Docker registry where the container image will be pushed.

hzn key create <yourcompany> <youremail>
# This command generates cryptographic keys used to sign and verify the services and patterns you publish to the Open Horizon Management Hub.

make build
# Builds the Docker container from your Dockerfile, similar to the local build process.

make push
# Pushes the built Docker image to your Docker registry, making it available for deployment through Open Horizon.

make publish-service
# Publishes the service to the Open Horizon Management Hub.

make publish-pattern
# Publishes the deployment pattern to the Management Hub.

make agent-run
# Commands the local Open Horizon agent to run the service according to the published pattern.

# Watch agreements and service logs
watch hzn agreement list
# Monitors and displays the agreements between your edge node and the management hub, indicating which services are deployed.

docker ps
# Lists all running Docker containers on your machine, allowing you to see the service container in action.

make test
# Runs tests to ensure the service is operating correctly within the Open Horizon environment.

make agent-stop
# Stops the Open Horizon agent, effectively undeploying the service from your node.
```

## Advanced Details

### SBoM Service Policy Generation

A Software Bill of Materials (SBoM) is a detailed list of components and versions that comprise a piece of software. With software exploints on the rise and open source code being critical to nearly every significant software project today, SBoM education is becoming more and more important. The following steps will lead you through creating an SBoM for the `web-hello-python:1.0.0` image, publish the SBoM data as a service policy, and use the Open-Horizon policy engine to control the deployment of the `web-hello-python` container to an edge node.


Generate and publish an SBoM for this service:

1. Create an SBoM for the `web-hello-python:1.0.0` docker image built in the previous section::
```shell
   make check-syft
   # This command uses the Syft tool to perform a comprehensive analysis of the container image built in previous steps. It outputs an SBoM that lists all components, their versions, and their dependencies within the image.
```

2. Generate and publish the service policy from SBoM data:
```shell
make sbom-policy-gen
# Generates a service policy based on the SBoM. This policy includes details about allowable software components and their versions, which can be used to enforce security standards across all deployments.

make publish-service
# Publishes the newly created service with its SBoM data to the Open Horizon Management Hub. This step is essential to ensure that all edge nodes using this service are aware of its components and comply with its policies.

make publish-service-policy
# Publishes the service policy associated with your service. This policy controls the deployment of the service based on the SBoM, ensuring that only compliant devices can run the service.

```

3. Publish a deployment policy for the service:
```shell
make publish-deployment-policy
# This step involves publishing a deployment policy that defines the criteria under which the service should be deployed to edge devices. This includes hardware requirements, geographical location, or any other relevant conditions that must be met for the service to be deployed.

```

### Authors

* [John Walicki](https://github.com/johnwalicki)
* [Troy Fine](https://github.com/t-fine)
___


Enjoy!  Give us [feedback](https://github.com/open-horizon-services/web-helloworld-python/issues) if you have suggestions on how to improve this tutorial.