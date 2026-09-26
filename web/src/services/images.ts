/** Уменьшает фото и сжимает в JPEG, чтобы не раздувать IndexedDB (как ImageService в iOS) */
export const downscaleImage = async (file: File, maxDimension = 1600): Promise<Blob> => {
  const bitmap = await createImageBitmap(file)
  const scale = Math.min(1, maxDimension / Math.max(bitmap.width, bitmap.height))
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(bitmap.width * scale)
  canvas.height = Math.round(bitmap.height * scale)
  canvas.getContext('2d')?.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
  bitmap.close()
  return new Promise((resolve, reject) =>
    canvas.toBlob(b => (b ? resolve(b) : reject(new Error('Не удалось обработать фото'))), 'image/jpeg', 0.8),
  )
}
