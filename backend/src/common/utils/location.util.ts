export type LocationPoint = {
  lat: number;
  lng: number;
};

const LAT_KEYS = ['lat', 'latitude'];
const LNG_KEYS = ['lng', 'lon', 'long', 'longitude'];

export function normalizeLocation(raw: unknown): LocationPoint | null {
  if (!raw || typeof raw !== 'object') return null;

  const location = raw as Record<string, unknown>;
  const lat = readCoordinate(location, LAT_KEYS);
  const lng = readCoordinate(location, LNG_KEYS);

  if (lat === null || lng === null) return null;

  return { lat, lng };
}

export function haversineDistanceMeters(
  a: LocationPoint,
  b: LocationPoint,
): number {
  const earthRadius = 6371000;
  const toRad = (value: number) => (value * Math.PI) / 180;

  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);

  const sinLat = Math.sin(dLat / 2);
  const sinLng = Math.sin(dLng / 2);

  const root =
    sinLat * sinLat +
    Math.cos(lat1) * Math.cos(lat2) * sinLng * sinLng;

  return 2 * earthRadius * Math.asin(Math.sqrt(root));
}

function readCoordinate(
  location: Record<string, unknown>,
  keys: string[],
): number | null {
  for (const key of keys) {
    const value = location[key];
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }

  return null;
}
