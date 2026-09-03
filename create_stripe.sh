#!/bin/bash
# Create 30 Stripe products + prices with rate limit handling
set -e

STRIPE_KEY=$(cd /opt/data && grep STRIPE_SECRET_KEY .env | head -1 | cut -d= -f2)
API="https://api.stripe.com/v1"

create_product() {
  local name="$1"
  local image="$2"
  local price_cents="$3"
  
  # Create product
  local prod_resp
  prod_resp=$(curl -s -X POST "$API/products" \
    -u "$STRIPE_KEY:" \
    -d "name=$name" \
    -d "metadata[brand]=calitoy" \
    -d "metadata[fulfiller]=printful" \
    -d "metadata[image]=$image")
  
  local prod_id
  prod_id=$(echo "$prod_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
  
  if [ -z "$prod_id" ]; then
    echo "ERROR creating product: $name"
    echo "$prod_resp" | head -5
    return 1
  fi
  
  sleep 1
  
  # Create price
  local price_resp
  price_resp=$(curl -s -X POST "$API/prices" \
    -u "$STRIPE_KEY:" \
    -d "product=$prod_id" \
    -d "unit_amount=$price_cents" \
    -d "currency=usd" \
    -d "type=one_time")
  
  local price_id
  price_id=$(echo "$price_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
  
  if [ -z "$price_id" ]; then
    echo "ERROR creating price for $name (prod: $prod_id)"
    echo "$price_resp" | head -5
    return 1
  fi
  
  echo "$name|$image|$price_cents|$prod_id|$price_id" >> /opt/data/calitoy-merch/stripe_products.txt
  echo "OK: $name -> $price_id"
  sleep 1
}

# Clear previous results
> /opt/data/calitoy-merch/stripe_products.txt

echo "=== Batch 1: Products 1-5 ==="
create_product "Calitoy Black Tee" "mockup-tee-black.jpg" 3200
create_product "Calitoy Rose Heart Tee" "mockup-tee-rose-heart.jpg" 3500
create_product "Calitoy Gothic 7 Tee" "calitoy-logo-gothic-7.jpg" 3500
create_product "Calitoy Retro 7 Tee" "calitoy-logo-retro-7.jpg" 3500
create_product "Calitoy Cali7 Joy Tee" "calitoy-logo-cali7-joy.jpg" 3500

sleep 2
echo "=== Batch 2: Products 6-10 ==="
create_product "Calitoy Brand Model Tee" "calitoy-brand-model.jpg" 4000
create_product "Calitoy x Kills Tee" "calitoy-collab-kills.jpg" 4000
create_product "Calitoy Muse x Kills Tee" "calitoy-collab-muse-kills.jpg" 4000
create_product "Lioness Album Tee" "calitoy-lioness-album.jpg" 3800
create_product "Calitoy Gold Circle Tee" "calitoy-logo-gold-circle.jpg" 3500

sleep 2
echo "=== Batch 3: Products 11-15 ==="
create_product "Calitoy Neon Metal Tee" "calitoy-logo-neon-metal.jpg" 3500
create_product "Calitoy Gold Sun Tee" "calitoy-logo-gold-sun.jpg" 3800
create_product "Calitoy Purple Sunflower Tee" "calitoy-logo-purple-sunflower.jpg" 3500
create_product "Calitoy Chrome Purple Tee" "calitoy-logo-chrome-purple.jpg" 3500
create_product "Calitoy Purple Lotus Tee" "calitoy-logo-purple-lotus.jpg" 3500

sleep 2
echo "=== Batch 4: Products 16-20 ==="
create_product "Calitoy Neon Purple Tee" "calitoy-logo-neon-purple.jpg" 3500
create_product "Calitoy Pink 3D Tee" "calitoy-logo-pink-3d.jpg" 3500
create_product "Calitoy Gold Emboss Tee" "calitoy-logo-gold-emboss.jpg" 3500
create_product "Calitoy Muse Gold Rose Tee" "calitoy-logo-muse-gold-rose.jpg" 3800
create_product "Calitoy Tattoo 7 Tee" "calitoy-logo-tattoo-7.jpg" 3500

sleep 2
echo "=== Batch 5: Products 21-25 ==="
create_product "Calitoy Tank Top" "mockup-tank-black.jpg" 2800
create_product "Calitoy Gothic Hoodie" "mockup-hoodie-gothic.jpg" 5500
create_product "Calitoy Cap" "mockup-cap-black.jpg" 2800
create_product "Calitoy Snapback" "mockup-cap-snapback.jpg" 3000
create_product "Calitoy Beanie" "mockup-beanie-black.jpg" 2400

sleep 2
echo "=== Batch 6: Products 26-30 ==="
create_product "Calitoy Mug" "mockup-mug-white.jpg" 1800
create_product "Calitoy Travel Mug" "mockup-mug-travel.jpg" 2200
create_product "Calitoy Sticker Pack" "mockup-sticker.jpg" 800
create_product "Calitoy Blanket" "mockup-blanket.jpg" 4500
create_product "Calitoy Tote Bag" "mockup-tote-natural.jpg" 2400

echo ""
echo "=== DONE: $(wc -l < /opt/data/calitoy-merch/stripe_products.txt) products created ==="
