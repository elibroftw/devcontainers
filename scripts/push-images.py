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
    help="e.g. `elibroftw/devcontainer-templates`. In GH actions: ${{ github.repository }}",
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


def docker_build(image_dir):
    # if not (image_dir / 'Dockerfile').exists():
    #     raise ValueError(f'ERROR: {image_dir} contains no Dockerfile')
    tag_base = image_dir.name
    version = "latest"
    # support tagged versions for people who stability (not me)
    # do not use git tags for all images!
    with suppress(FileNotFoundError):
        with open(image_dir / "manifest.json", encoding="utf-8") as fp:
            version = json.load(fp)["version"]
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


with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
    futures = []
    for dir in Path(args.images_dir).iterdir():
        if dir.is_dir():
            futures.append(executor.submit(docker_build, dir))
    success = 0
    for future in concurrent.futures.as_completed(futures):
        try:
            future.result()
            success += 1
        except (ValueError, subprocess.CalledProcessError) as e:
            print(e, file=sys.stderr)
    if success == 0:
        print("Not a single image was successfully built", file=sys.stderr)
        sys.exit(1)
