#!/usr/bin/env python3
import argparse
import concurrent.futures
import json
import subprocess
import sys
from contextlib import suppress
from pathlib import Path

parser = argparse.ArgumentParser(
    description="Multi-Platform Base[d] Image Devcontainer Pusher"
)
# https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/accessing-contextual-information-about-workflow-runs#github-context
parser.add_argument(
    "--namespace",
    required=True,
    action="store",
    help="e.g. `elibroftw/devcontainers`. In GH actions: ${{ github.repository }}",
)
parser.add_argument(
    "--registry",
    action="store",
    default="ghcr.io",
    help="container registry",
)
parser.add_argument(
    "--images-dir",
    action="store",
    default="src/images",
    help="location of NAME/Dockerfile files",
)

# not exposed as an argument because why else would you need to use this script?
PLATFORM = "linux/amd64,linux/arm64"
# --registry-path devcontainers

args = parser.parse_args()

# QEMU manual install for multi-platform build
# https://docs.docker.com/build/building/multi-platform/#qemu
# subprocess.check_call(
#     ["docker", "run", "--privileged", "--rm", "tonistiigi/binfmt", "--install", "all"]
# )


def read_manifest(image_dir):
    # support tagged versions for people who stability (not me)
    # do not use git tags for all images!
    with suppress(FileNotFoundError):
        with open(image_dir / "manifest.json", encoding="utf-8") as fp:
            return json.load(fp)
    return {}


def docker_build(image_dir):
    # if not (image_dir / 'Dockerfile').exists():
    #     raise ValueError(f'ERROR: {image_dir} contains no Dockerfile')
    tag_base = image_dir.name
    version = read_manifest(image_dir).get("version", "latest")
    versioned_image_name = f"{args.registry}/{args.namespace}/{tag_base}:{version}"
    latest_image_name = f"{args.registry}/{args.namespace}/{tag_base}:latest"
    print(
        f"building and pushing {versioned_image_name} via devcontainer for the following platform(s): {PLATFORM}"
    )
    subprocess.check_call(
        [
            "devcontainer",
            "build",
            "--log-level=info",
            f"--workspace-folder={image_dir}",
            f"--image-name={versioned_image_name}",
            f"--image-name={latest_image_name}",
            f"--platform={PLATFORM}",
            "--push",
        ]
    )


# An image whose Dockerfile says FROM another image in here declares that as
# `"dependsOn": ["base-almalinux"]`. Without it the two builds race, and the
# derived image is built against whatever was published on the previous run, so a
# base image fix takes two runs to reach the images built on top of it.
images = {d.name: d for d in Path(args.images_dir).iterdir() if d.is_dir()}
depends_on = {
    # a dependency outside this directory is somebody else's registry, not ours to order
    name: {d for d in read_manifest(d_path).get("dependsOn", []) if d in images}
    for name, d_path in images.items()
}


# in waves: everything whose dependencies are already pushed, in parallel
built = set()
failed = set()
pending = set(images)
while pending:
    ready = sorted(name for name in pending if depends_on[name] <= built)
    if not ready:
        # either a dependency failed, or two manifests point at each other
        blocked = sorted(name for name in pending if depends_on[name] & failed)
        for name in blocked or sorted(pending):
            reason = "a dependency failed" if blocked else "a dependsOn cycle"
            print(f"skipping {name}: {reason}", file=sys.stderr)
        failed |= pending
        break
    pending -= set(ready)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(docker_build, images[name]): name for name in ready}
        for future in concurrent.futures.as_completed(futures):
            name = futures[future]
            try:
                future.result()
                built.add(name)
            except (ValueError, subprocess.CalledProcessError) as e:
                print(e, file=sys.stderr)
                failed.add(name)

if not built:
    print("Not a single image was successfully built", file=sys.stderr)
    sys.exit(1)
if failed:
    print(f"failed to build: {', '.join(sorted(failed))}", file=sys.stderr)
    sys.exit(1)
