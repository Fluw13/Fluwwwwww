const ALLOWED_IMAGE_HOSTS = new Set(['images.openfoodfacts.org', 'static.openfoodfacts.org']);
const IMAGE_KINDS = Object.freeze(['front', 'ingredients', 'nutrition']);
// Open Food Facts serves every selected image at 100, 200, 400 px and full size: ".../front_vi.12.400.jpg".
const SIZE_SUFFIX = /\.(\d+|full)\.jpg$/;

const isAllowedImageUrl = (value) => {
    if (typeof value !== 'string') {
        return false;
    }

    try {
        const url = new URL(value);
        return url.protocol === 'https:' && ALLOWED_IMAGE_HOSTS.has(url.hostname);
    } catch {
        return false;
    }
};

const withSize = (url, size) => url.replace(SIZE_SUFFIX, '.' + size + '.jpg');

const toImageSet = (url) => {
    if (!isAllowedImageUrl(url) || !SIZE_SUFFIX.test(url)) {
        return null;
    }

    return { small: withSize(url, 200), display: withSize(url, 400), full: withSize(url, 'full') };
};

const pickLanguageVariant = (variants, languages) => {
    if (variants === null || typeof variants !== 'object') {
        return null;
    }

    for (const language of languages) {
        if (typeof variants[language] === 'string') {
            return variants[language];
        }
    }

    return Object.values(variants).find((value) => typeof value === 'string') ?? null;
};

const readImage = (raw, kind, languages) => {
    const selected = pickLanguageVariant(raw.selected_images?.[kind]?.display, languages);
    return toImageSet(selected ?? raw['image_' + kind + '_url']);
};

const readImages = (raw, languages) => Object.fromEntries(IMAGE_KINDS.map((kind) => [kind, readImage(raw, kind, languages)]));

const readThumbnailUrl = (raw) => toImageSet(raw.image_front_small_url ?? raw.image_front_url)?.small ?? null;

module.exports = { readImages, readThumbnailUrl, isAllowedImageUrl };
