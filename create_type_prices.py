#!/usr/bin/env python3
"""Create 20 Stripe products (one per product TYPE) with prices."""
import os, json, time, urllib.request, urllib.error, urllib.parse

# Load Stripe key
STRIPE_KEY = ""
with open('/opt/data/.env') as f:
    for line in f:
        if line.startswith('STRIPE_SECRET_KEY'):
            STRIPE_KEY = line.split('=', 1)[1].strip().strip('"').strip("'")
            break
if not STRIPE_KEY:
    raise RuntimeError("No STRIPE_SECRET_KEY found")

PRODUCT_TYPES = [
    {"name": "Unisex Staple Tee", "price_cents": 3200},
    {"name": "Unisex Pullover Hoodie", "price_cents": 5200},
    {"name": "Unisex Heavy Blend Hoodie", "price_cents": 4800},
    {"name": "Unisex Crew Sweatshirt", "price_cents": 4200},
    {"name": "Unisex Tank Top", "price_cents": 2800},
    {"name": "Unisex Long Sleeve Tee", "price_cents": 3600},
    {"name": "Unisex Tri-Blend Tee", "price_cents": 3800},
    {"name": "Cuffed Beanie", "price_cents": 2400},
    {"name": "Knit Beanie", "price_cents": 2200},
    {"name": "Snapback Cap", "price_cents": 2800},
    {"name": "Classic Snapback", "price_cents": 3000},
    {"name": "Classic Dad Hat", "price_cents": 2800},
    {"name": "White Mug", "price_cents": 1800},
    {"name": "Black Mug", "price_cents": 1800},
    {"name": "Eco Tote Bag", "price_cents": 2400},
    {"name": "Kiss-Cut Stickers", "price_cents": 800},
    {"name": "Beach Towel", "price_cents": 3500},
    {"name": "Basic Softstyle Tee", "price_cents": 2800},
    {"name": "Unisex Joggers", "price_cents": 3800},
    {"name": "Unisex Long Sleeve Shirt", "price_cents": 3400},
]

import base64
AUTH = base64.b64encode(f"{STRIPE_KEY}:".encode()).decode()

def stripe_api(endpoint, data):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(
        f"https://api.stripe.com/v1/{endpoint}",
        data=body,
        headers={"Authorization": f"Basic {AUTH}"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err_body = e.read().decode()
        print(f"  ERROR: {e.code} {err_body[:200]}")
        return None

results = []
for i, pt in enumerate(PRODUCT_TYPES):
    print(f"[{i+1}/20] Creating: {pt['name']} (${pt['price_cents']/100:.2f})")
    # Create product
    prod = stripe_api("products", {
        "name": pt["name"],
        "metadata[brand]": "calitoy",
        "metadata[fulfiller]": "printful",
    })
    if not prod:
        print(f"  FAILED to create product, skipping")
        continue
    prod_id = prod["id"]
    # Create price
    price = stripe_api("prices", {
        "product": prod_id,
        "unit_amount": str(pt["price_cents"]),
        "currency": "usd",
    })
    if not price:
        print(f"  FAILED to create price")
        continue
    price_id = price["id"]
    results.append({
        "name": pt["name"],
        "price_cents": pt["price_cents"],
        "product_id": prod_id,
        "price_id": price_id,
    })
    print(f"  OK: product={prod_id} price={price_id}")
    if i < len(PRODUCT_TYPES) - 1:
        time.sleep(1)

# Save results
out_path = "/opt/data/calitoy-merch/stripe_type_prices.json"
with open(out_path, "w") as f:
    json.dump(results, f, indent=2)
print(f"\nSaved {len(results)} prices to {out_path}")
