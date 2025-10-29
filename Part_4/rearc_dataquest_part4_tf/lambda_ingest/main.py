
import json, os, time, hashlib, re
from urllib.parse import urljoin, urlparse
import urllib.request
import boto3

S3_BUCKET = os.environ["S3_BUCKET"]
POPULATION_S3_KEY = os.environ.get("POPULATION_S3_KEY", "part2/population_data.json")
DATAUSA_POP_API = os.environ.get("DATAUSA_POP_API")
ENABLE_BLS_PART1_SYNC = os.environ.get("ENABLE_BLS_PART1_SYNC","true").lower() == "true"
BLS_BASE_URL = os.environ.get("BLS_BASE_URL")

s3 = boto3.client("s3")

def _http_get(url, timeout=30):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return r.read()

def _put_if_changed(key: str, content: bytes):
    # idempotent upload based on SHA256 of content
    new_hash = hashlib.sha256(content).hexdigest()
    try:
        # try to fetch existing object etag via metadata hash
        head = s3.head_object(Bucket=S3_BUCKET, Key=key)
        old_hash = head.get("Metadata", {}).get("sha256", "")
        if old_hash == new_hash:
            print(f"[skip] {key} unchanged ({new_hash[:8]})")
            return False
    except s3.exceptions.NoSuchKey:
        pass
    except Exception as e:
        print(f"[warn] head_object failed for {key}: {e}")

    s3.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=content,
        Metadata={"sha256": new_hash},
        ContentType="application/json" if key.endswith(".json") else "text/plain"
    )
    print(f"[put] {key} ({len(content)} bytes, sha256={new_hash[:8]})")
    return True

def mirror_bls_dataset():
    if not BLS_BASE_URL:
        print("BLS_BASE_URL not set; skipping Part 1 mirror")
        return
    index_bytes = _http_get(BLS_BASE_URL)
    listing = index_bytes.decode("utf-8", errors="ignore")
    # href extraction
    files = re.findall(r'href="([^"]+)"', listing)
    count = 0
    for f in files:
        if f.endswith("/"):
            continue
        url = urljoin(BLS_BASE_URL, f)
        try:
            content = _http_get(url)
        except Exception as e:
            print(f"[warn] fetch failed {url}: {e}")
            continue
        key = f"part1/{f}"
        _put_if_changed(key, content)
        count += 1
    print(f"[part1] mirrored {count} files from {BLS_BASE_URL}")

def write_population_json():
    if not DATAUSA_POP_API:
        raise RuntimeError("DATAUSA_POP_API env var missing")
    data = _http_get(DATAUSA_POP_API)
    # sanity check JSON
    try:
        obj = json.loads(data.decode("utf-8"))
    except Exception as e:
        raise RuntimeError(f"Population API did not return JSON: {e}")
    # pretty print with stable key order
    pretty = json.dumps(obj, indent=2, sort_keys=True).encode("utf-8")
    _put_if_changed(POPULATION_S3_KEY, pretty)

def lambda_handler(event, context):
    print("Starting ingest...")
    if ENABLE_BLS_PART1_SYNC:
        mirror_bls_dataset()
    write_population_json()
    return {"ok": True}
