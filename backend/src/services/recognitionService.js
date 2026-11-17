const HttpError = require('../errors/httpError');

const IMAGE_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']);

/**
 * Asks the vision model which foods a photo shows. The photo is only passed through: it is never stored or logged,
 * and nothing about the user is sent with it.
 */
const createRecognitionService = ({ gemini, logger = console }) => ({
    recognize: async ({ image, contentType }) => {
        if (!gemini.isConfigured) {
            throw new HttpError(503, 'RECOGNITION_NOT_CONFIGURED', 'Máy chủ chưa bật nhận diện ảnh. Hãy tìm theo tên món.');
        }
        const mimeType = typeof contentType === 'string' ? contentType.split(';')[0].trim().toLowerCase() : '';
        if (!IMAGE_TYPES.has(mimeType)) {
            throw new HttpError(415, 'UNSUPPORTED_IMAGE', 'Ảnh cần ở dạng JPEG, PNG, WebP hoặc HEIC.');
        }
        if (!Buffer.isBuffer(image) || image.length === 0) {
            throw new HttpError(400, 'IMAGE_REQUIRED', 'Chưa có ảnh để nhận diện.');
        }
        try {
            return await gemini.recognizeFood({ image, mimeType });
        } catch (error) {
            // Every failure is logged, so a bad key or a region the free tier does not cover shows up on Render.
            logger.error('[Recognition]', error instanceof HttpError ? `${error.code} ${error.detail ?? ''}`.trim() : error.message);
            if (error instanceof HttpError) {
                throw error;
            }
            throw new HttpError(
                503,
                'RECOGNITION_UNAVAILABLE',
                'Chưa nhận diện được ảnh lúc này. Hãy thử lại sau hoặc tìm theo tên món.',
            );
        }
    },
});

module.exports = createRecognitionService;
module.exports.IMAGE_TYPES = IMAGE_TYPES;
