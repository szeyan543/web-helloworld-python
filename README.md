# web-helloworld-python

Extremely simple HTTP server (written in Python) that responds on port 8000 with a hello message.

Begin by editing the variables at the top of the Makefile as desired. If you plan to push it to a Docker registery, make sure you give your docker ID. You may also want to create unique names for your **service** and **pattern** (necessary if you are sharing a tenancy with other users and you are all publishing this service).

To play with this outside of Open Horizon:

```
make build
make run
...
make test
make stop
```

When you are ready to try it inside Open Horizon:

```
docker login
hzn key create **yourcompany** **youremail**
make build
make push
make publish-service
make publish-pattern
```

Once it is published, you can get the agent to deploy it:

```
make agent-run
```

Then you can watch the agreement form, see the container run, then test it:

```
watch hzn agreement list
... (runs forever, so press Ctrl-C when you want to stop)
docker ps
make test
```

Then when you are done you can get the agent to stop running it:

```
make agent-stop
```

# SBoM Service Policy Generation 

A Software Bill of Materials (SBoM) is a detailed list of components and versions that comprise a piece of software. With software exploints on the rise and open source code being critical to nearly every significant software project today, SBoM education is becoming more and more important. The following steps will lead you through creating an SBoM for the `web-hello-python:1.0.0` image, publish the SBoM data as a service policy, and use the Open-Horizon policy engine to control the deployment of the `web-hello-python` container to an edge node.

1. Create an SBoM for the `web-hello-python:1.0.0` docker image built in the previous section:
```
make check-syft
```

2. Generate a service policy from the SBoM data:
```
make sbom-policy-gen
```

3. Publish the service and service policy:
```
make publish-service
make publish-service-policy
```

4. Publish a deployment policy for the service:
```
make publish-deployment-policy
```

