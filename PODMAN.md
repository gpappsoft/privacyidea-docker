[![Docker](https://github.com/gpappsoft/privacyidea-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/gpappsoft/privacyidea-docker/actions/workflows/docker-publish.yml)

# Using Podman


What work:
- running the image manually with podman
- Makefile targets ```build``` ```cert``` ```secret``` ```build``` ```push``` ```run``` ```clean``` ```distclean``` 

What does not work:
- Makefile target ```stack``` 

### Requirements

- [podman](https://podman.io)
- [buildah](https://buildah.io/)


## Using the ```make``` targets with Podman
To use podman there are some extra arguments required.
**Always** add the following arguments  to the ```make```command:

```
 CONTAINER_ENGINE=podman BUILDER="buildah bud"
 ```
```BUILDER```is only needed for the ```build``` target.
 #### Examples

```
make cert secert build CONTAINER_ENGINE=podman BUILDER="buildah bud"
 ```
 ```
make run CONTAINER_ENGINE=podman 
 ```

## Running a full stack with Podman 

There is no full stack provided by this project at the moment. \
Maybe in the future I will provide a short HOWTO here and a k8s yaml file for kube play. Also the same for a helm chart.  :thinking: 