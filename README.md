# GT-post - Postprocessing of Delft3D-Geotool models

## Container

Build the CPU-only production image using the committed Pixi lockfile:

```sh
docker build --platform linux/amd64 -t gtpost:yolo .
```

The image installs dependencies in a builder stage and runs as UID 1001.
The entrypoint activates the installed environment, including GDAL and PROJ
settings, and invokes Python directly. Pixi and its build caches are not shipped
in the runtime image; startup does not install or update dependencies.

Select another environment at build time with `--build-arg PIXI_ENV=<environment>`.
Setting `PIXI_ENV` when running the container does not switch environments.
Dependency changes require regenerating `pixi.lock` with Pixi 0.67.2 and rebuilding
the image. Outside the container, activate the desired Python environment before
running `entrypoint.sh`.

