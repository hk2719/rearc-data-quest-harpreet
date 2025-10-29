
import json, os, boto3, statistics

S3_BUCKET = os.environ["S3_BUCKET"]
POPULATION_S3_KEY = os.environ.get("POPULATION_S3_KEY", "part2/population_data.json")

s3 = boto3.client("s3")

def load_population():
    obj = s3.get_object(Bucket=S3_BUCKET, Key=POPULATION_S3_KEY)
    data = json.loads(obj["Body"].read().decode("utf-8"))
    # The DataUSA "data" has records with fields like Year and Population
    # Normalize a simple list of (year, population)
    rows = data.get("data") or data.get("records") or data
    out = []
    for r in rows:
        year = int(r.get("Year") or r.get("year"))
        pop  = int(r.get("Population") or r.get("value") or 0)
        out.append((year, pop))
    return out

def compute_mean_std_2013_2018(rows):
    # filter inclusive range
    values = [pop for (year, pop) in rows if 2013 <= year <= 2018]
    if not values:
        return None
    mean_v = statistics.fmean(values)
    std_v  = statistics.pstdev(values)  # population stddev
    return mean_v, std_v

def lambda_handler(event, context):
    # SQS will batch messages; event may contain many records, but we just recompute once.
    rows = load_population()
    stats = compute_mean_std_2013_2018(rows)
    if stats:
        mean_v, std_v = stats
        print(f"[report] Population 2013-2018 mean={mean_v:.2f} stddev={std_v:.2f}")
    else:
        print("[report] No rows found in 2013-2018 range")
    return {"ok": True}
