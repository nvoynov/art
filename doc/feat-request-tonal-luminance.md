---
title: "Feature Request: Tonal & Luminance Curation Engine"
status: "Proposed"
component: "Rake Build Pipeline / Generative Mosaic Engine"
---

# Feature Request: Tonal & Luminance Curation Engine

## 1. Overview & Motivation

Currently, the homepage generative mosaic (`mosaic.js`) curates photographic compositions using random mixing (`chaos`), album grouping (`series`), and capture dates (`season`). While effective for structural variety, these modes do not account for the visual weight, brightness, or color harmony of individual frames.

To elevate the homepage into a true editorial gallery wall, we want to extract **tonal and color metadata** during the static build phase (via ImageMagick) and expose new **luminance- and color-driven curation strategies** in the frontend engine.

## 2. Build Pipeline Enhancements (Ruby / Rake)

During the thumbnail generation or manifest compilation phase (`seriesmap.json`), each thumbnail (`400x600` WebP) should be analyzed using **ImageMagick** to extract lightweight perceptual metrics.

### Target Metrics per Image

* **`luma`** (`Float`, `0.000`–`1.000`): Mean grayscale brightness (`-colorspace Gray -format "%[fx:mean]"`).
* **`contrast`** (`Float`, `0.000`–`0.500`): Standard deviation of grayscale luminance (`%[fx:standard_deviation]`), distinguishing misty/flat frames from high-contrast graphics.
* **`hue`** (`Float`, `0.000`–`1.000`): Mean hue in HSB color space (`-colorspace HSB -format "%[fx:mean.r]"`).
* **`saturation`** (`Float`, `0.000`–`1.000`): Mean saturation in HSB color space (`%[fx:mean.g]`).
* **`dominant_hex`** (`String`, e.g. `"#4a5359"`): Averaged dominant color extracted via `-scale 1x1! -format "#%[hex:u.p{0,0}]"`.

### Extended `seriesmap.json` Schema

```json
{
  "series": {
    "gravity-and-grace": {
      "P3276394.webp": {
        "captured_at": "2018-01-01 12:46:54 +0200",
        "luma": 0.342,
        "contrast": 0.215,
        "hue": 0.581,
        "saturation": 0.184,
        "dominant_hex": "#4a5359"
      }
    }
  }
}
```

### Performance & Caching Considerations

* Analysis must run against the small `400x600` thumbnails to keep execution time under ~10ms per image.
* Extracted tonal values should be cached in `seriesmap.json` (or an intermediate negative registry) so incremental `rake build` runs do not re-analyze unchanged assets.

## 3. Frontend Curation Strategies (`assets/js/mosaic/curators.js`)

Once tonal metadata is present in `seriesmap.json`, `MosaicCurator` will support three new curation modes alongside `chaos`, `series`, and `season`:

1. **`gradient` (Vertical Visual Gravity)**
   * Selects a balanced pool of frames and sorts each column by `luma` descending (bright, airy frames at the top; heavy, dark frames anchored at the bottom) or ascending.
2. **`muted` (Quiet / Low-Saturation Wall)**
   * Filters frames with low chromatic intensity (`saturation < 0.22`) to assemble a calm, near-monochrome composition.
   * Pairs naturally with a sparser `GEOMETRY_PROFILES` preset (increased whitespace/spacers).
3. **`harmony` (Chromatic Key)**
   * Picks a random anchor photograph and populates the columns with frames whose `hue` falls within a narrow threshold (`±0.08`) and compatible `luma` range.

## 4. Implementation Milestones

* [ ] **Milestone 1:** Implement `extract_tonal_meta(path)` helper in the Ruby build pipeline using existing ImageMagick CLI bindings.
* [ ] **Milestone 2:** Populate `luma`, `contrast`, `hue`, `saturation`, and `dominant_hex` into `seriesmap.json` with incremental caching.
* [ ] **Milestone 3:** Extend `MosaicCurator` (`curators.js`) with `gradient`, `muted`, and `harmony` strategies with graceful fallback when tonal metadata is missing.
* [ ] **Milestone 4:** Introduce matching geometry presets in `layout.js` (e.g., higher spacer frequency for `muted` mode) and update the playback playlist in `mosaic.js`.

