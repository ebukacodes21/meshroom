import os
import boto3
import tempfile
import subprocess
from pathlib import Path

def download_depth_results(s3, bucket, prefix, dest_dir):
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith("_depth.png"):
                local_path = Path(dest_dir) / Path(key).name
                s3.download_file(bucket, key, str(local_path))

def upload_results(s3, bucket, source_dir, prefix):
    for file in Path(source_dir).rglob("*"):
        if file.is_file():
            s3.upload_file(str(file), bucket, f"{prefix}{file.name}")

def run_meshroom_pipeline(working_dir):
    subprocess.run([
        "meshroom_batch",
        "--input", str(working_dir),
        "--output", str(Path(working_dir) / "output")
    ], check=True)

def main():
    user_id = os.environ.get("USER_ID")
    job_id = os.environ.get("JOB_ID")
    bucket = os.environ.get("S3_BUCKET")

    if not all([user_id, job_id, bucket]):
        print("❌ Missing required environment variables.")
        return

    input_prefix = f"processed/{user_id}/{job_id}/"
    output_prefix = f"meshed/{user_id}/{job_id}/"

    s3 = boto3.client("s3")
    with tempfile.TemporaryDirectory() as tmpdir:
        download_depth_results(s3, bucket, input_prefix, tmpdir)
        run_meshroom_pipeline(tmpdir)
        upload_results(s3, bucket, Path(tmpdir) / "output", output_prefix)

        print("✅ 3D model generated and uploaded.")

if __name__ == "__main__":
    main()
