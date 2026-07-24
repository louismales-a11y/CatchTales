#!/usr/bin/env python3
"""
Convert CatchTales fishing guide HTML pages to structured JSON for the Flutter app.
Produces:
  assets/guides/fishing_regions.json   — all region pages
  assets/guides/fishing_hubs.json      — province/state hub pages
  assets/guides/blog_posts.json        — blog posts
"""
import os, re, json
from datetime import datetime

SITE = '/home/louis/catchtales-site'
OUT = '/home/louis/CatchTales/assets/guides'
os.makedirs(OUT, exist_ok=True)

def extract_text(html):
    """Strip HTML tags and decode entities."""
    text = re.sub(r'<[^>]+>', '', html)
    text = text.replace('&amp;', '&').replace('&nbsp;', ' ').replace('&lt;', '<').replace('&gt;', '>')
    text = re.sub(r'&[a-zA-Z]+;', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def extract_region(fpath, slug):
    """Extract structured data from a fishing-near region page."""
    with open(fpath, 'r', encoding='utf-8') as f:
        html = f.read()
    
    title_m = re.search(r'<title>([^<]+)</title>', html)
    title = title_m.group(1).replace(' | CatchTales', '').replace('Fishing Near ', '').strip() if title_m else slug
    
    desc_m = re.search(r'<meta name="description" content="([^"]+)"', html)
    description = desc_m.group(1) if desc_m else ''
    
    h1_m = re.search(r'<h1>([^<]+)</h1>', html)
    h1 = h1_m.group(1) if h1_m else title
    
    subtitle_m = re.search(r'<p class="subtitle">([^<]+)</p>', html)
    subtitle = extract_text(subtitle_m.group(1)) if subtitle_m else ''
    
    # Extract intro paragraph
    content_div = re.search(r'<div class="content-page">(.*?)</div>\s*<footer', html, re.DOTALL)
    intro = ''
    spots_data = []
    
    if content_div:
        content = content_div.group(1)
        
        # Get intro (first p that's not a tip/CTA)
        ps = re.findall(r'<p>([^<]+)</p>', content)
        for p in ps:
            txt = extract_text(p)
            if txt and 'Plan smarter' not in txt and 'CatchTales' not in txt and len(txt) > 50:
                intro = txt[:500]
                break
        
        # Get spots
        spot_pattern = re.compile(
            r'<h2[^>]*>([^<]+)</h2>\s*'
            r'(?:<span class="distance">([^<]*)</span>)?\s*'
            r'(<p>[^<]*</p>)?',
            re.DOTALL
        )
        for m in spot_pattern.finditer(content):
            name = extract_text(m.group(1)).strip()
            
            # Skip non-spot sections like "Fishing Tips...", "Get CatchTales", etc.
            if not re.match(r'^\d+\.', name):
                continue
            
            distance = extract_text(m.group(2)).strip() if m.group(2) else ''
            desc_html = m.group(3) or ''
            spot_desc = extract_text(desc_html) if desc_html else ''
            
            # Clean up numbering like "1. Red River" → "Red River"
            clean_name = re.sub(r'^\d+\.\s*', '', name).strip()
            
            # Extract species from name (parenthetical)
            species = []
            species_m = re.search(r'\(([^)]+)\)', clean_name)
            if species_m:
                species = [s.strip() for s in species_m.group(1).split(',')]
                clean_name = re.sub(r'\s*\([^)]*\)', '', clean_name).strip()
            
            spots_data.append({
                'name': clean_name,
                'original_name': name,
                'distance': distance,
                'description': spot_desc[:500] if spot_desc else '',
                'species': species
            })
    
    # Try to find parent hub from breadcrumb
    parent_hub = ''
    region_country = 'us'
    parent_match = re.search(r'href="/(fishing-in-(?:canada|united-states)/([^"/]+))', html)
    if parent_match:
        parent_hub = parent_match.group(2)
        parent_path = parent_match.group(1)
        region_country = 'ca' if 'canada' in parent_path else 'us'
    
    return {
        'slug': slug,
        'title': title,
        'h1': h1,
        'subtitle': subtitle,
        'description': description[:300],
        'intro': intro,
        'spots': spots_data,
        'parent_hub': parent_hub,
        'country': region_country
    }

def extract_hub(fpath, slug):
    """Extract structured data from a province/state hub page."""
    with open(fpath, 'r', encoding='utf-8') as f:
        html = f.read()
    
    title_m = re.search(r'<title>([^<]+)</title>', html)
    title = title_m.group(1).replace(' | CatchTales', '').replace('Fishing in ', '').replace(' — Regions & Fishing Guides', '').strip() if title_m else slug
    
    desc_m = re.search(r'<meta name="description" content="([^"]+)"', html)
    description = desc_m.group(1) if desc_m else ''
    
    h1_m = re.search(r'<h1>([^<]+)</h1>', html)
    h1 = h1_m.group(1) if h1_m else title
    
    # Get regions listed on this hub page
    regions = re.findall(r'href="/fishing-near/([^"/]+)/"', html)
    
    # Get stats
    stats = re.findall(r'<div class="num">([^<]+)</div>', html)
    stat_labels = re.findall(r'<div class="lbl">([^<]+)</div>', html)
    
    # Get note/description
    note_m = re.search(r'<p class="note">([^<]+)</p>', html)
    note = extract_text(note_m.group(1)) if note_m else ''
    
    # Determine country (use path-based check, not HTML content — nav links have Canada in all pages)
    is_canada = os.path.exists(os.path.join(SITE, 'fishing-in-canada', slug))
    
    return {
        'slug': slug,
        'title': title,
        'h1': h1,
        'description': description[:300],
        'note': note[:500],
        'regions': regions,
        'stats': dict(zip(stat_labels, stats)),
        'country': 'ca' if is_canada else 'us'
    }

def extract_blog(fpath, slug):
    """Extract structured data from a blog post."""
    with open(fpath, 'r', encoding='utf-8') as f:
        html = f.read()
    
    title_m = re.search(r'<title>([^<]+)</title>', html)
    title = title_m.group(1).replace(' | CatchTales', '').strip() if title_m else slug
    
    desc_m = re.search(r'<meta name="description" content="([^"]+)"', html)
    description = desc_m.group(1) if desc_m else ''
    
    # Get first paragraph of content
    body = re.search(r'<div class="content-page">(.*?)</div>\s*<footer', html, re.DOTALL)
    intro = ''
    if body:
        ps = re.findall(r'<p>([^<]+)</p>', body.group(1))
        for p in ps:
            txt = extract_text(p)
            if txt and len(txt) > 80 and 'Plan smarter' not in txt:
                intro = txt[:500]
                break
    
    return {
        'slug': slug,
        'title': title,
        'description': description[:300],
        'intro': intro
    }

# ─── Build regions ───
regions = []
for slug in sorted(os.listdir(os.path.join(SITE, 'fishing-near'))):
    fpath = os.path.join(SITE, f'fishing-near/{slug}/index.html')
    if os.path.exists(fpath):
        try:
            r = extract_region(fpath, slug)
            regions.append(r)
        except Exception as e:
            print(f"  ⚠️  Error processing region {slug}: {e}")

regions.sort(key=lambda r: r['title'])
with open(os.path.join(OUT, 'fishing_regions.json'), 'w', encoding='utf-8') as f:
    json.dump(regions, f, indent=2, ensure_ascii=False)
print(f"✅ {len(regions)} regions → fishing_regions.json")

# ─── Build hubs ───
hubs = []

# Canada
for slug in sorted(os.listdir(os.path.join(SITE, 'fishing-in-canada'))):
    if slug == 'index.html':
        continue
    fpath = os.path.join(SITE, f'fishing-in-canada/{slug}/index.html')
    if os.path.exists(fpath):
        try:
            h = extract_hub(fpath, slug)
            hubs.append(h)
        except Exception as e:
            print(f"  ⚠️  Error processing hub {slug}: {e}")

# US
for slug in sorted(os.listdir(os.path.join(SITE, 'fishing-in-united-states'))):
    if slug == 'index.html':
        continue
    fpath = os.path.join(SITE, f'fishing-in-united-states/{slug}/index.html')
    if os.path.exists(fpath):
        try:
            h = extract_hub(fpath, slug)
            hubs.append(h)
        except Exception as e:
            print(f"  ⚠️  Error processing hub {slug}: {e}")

hubs.sort(key=lambda r: r['title'])
with open(os.path.join(OUT, 'fishing_hubs.json'), 'w', encoding='utf-8') as f:
    json.dump(hubs, f, indent=2, ensure_ascii=False)
print(f"✅ {len(hubs)} hubs → fishing_hubs.json")

# ─── Build blog posts ───
posts = []
for slug in sorted(os.listdir(os.path.join(SITE, 'blog'))):
    if slug == 'index.html' or slug == 'feed.xml':
        continue
    fpath = os.path.join(SITE, f'blog/{slug}/index.html')
    if os.path.exists(fpath):
        try:
            p = extract_blog(fpath, slug)
            posts.append(p)
        except Exception as e:
            print(f"  ⚠️  Error processing blog {slug}: {e}")

with open(os.path.join(OUT, 'blog_posts.json'), 'w', encoding='utf-8') as f:
    json.dump(posts, f, indent=2, ensure_ascii=False)
print(f"✅ {len(posts)} blog posts → blog_posts.json")

# ─── Summary ───
total_size = sum(
    os.path.getsize(os.path.join(OUT, f))
    for f in os.listdir(OUT) if f.endswith('.json')
)
print(f"\n📦 Total JSON size: {total_size/1024:.1f} KB")
print(f"📍 {OUT}/")
