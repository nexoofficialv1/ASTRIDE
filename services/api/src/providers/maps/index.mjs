import { getProviderCredential } from '../../config/provider-vault.mjs';

const R = 6371000;
const rad = (value) => value * Math.PI / 180;
const KALNA = { lat: 23.2196, lng: 88.3628 };
const searchCache = new Map();
const CACHE_TTL_MS = 5 * 60 * 1000;

const distanceM = (a, b) => {
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.lat)) *
      Math.cos(rad(b.lat)) *
      Math.sin(dLng / 2) ** 2;
  return Math.round(2 * R * Math.asin(Math.sqrt(x)));
};

const fallbackRoute = (provider, origin, destination) => {
  const direct = distanceM(origin, destination);
  const estimated = Math.round(direct * 1.22);
  return {
    provider,
    origin,
    destination,
    distanceM: estimated,
    durationS: Math.max(
      60,
      Math.round(estimated / (18_000 / 3600)),
    ),
    geometry: [origin, destination],
    estimated: true,
  };
};

async function fetchJson(url, options = {}, timeoutMs = 12_000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`Map provider HTTP ${response.status}`);
    }

    return await response.json();
  } finally {
    clearTimeout(timer);
  }
}

const cred = (name, mode) =>
  getProviderCredential('maps', name, mode) || {};

const finiteNumber = (value, fallback = null) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const clamp = (value, min, max) =>
  Math.max(min, Math.min(max, value));

const cleanText = (value) =>
  String(value || '').replace(/\s+/g, ' ').trim();

const localNameFromAddress = (address = {}) =>
  cleanText(
    address.amenity ||
      address.shop ||
      address.tourism ||
      address.leisure ||
      address.building ||
      address.railway ||
      address.bus_stop ||
      address.road ||
      address.neighbourhood ||
      address.suburb ||
      address.village ||
      address.town ||
      address.city ||
      address.county ||
      '',
  );

const placeName = (item) => {
  const named =
    item?.namedetails?.name ||
    item?.namedetails?.['name:bn'] ||
    item?.namedetails?.['name:en'];

  return cleanText(
    named ||
      item?.name ||
      localNameFromAddress(item?.address) ||
      String(item?.display_name || '').split(',')[0],
  );
};

const placeSubtitle = (item, name) => {
  const display = cleanText(item?.display_name);
  if (!display) return '';

  const lowerName = cleanText(name).toLowerCase();
  const parts = display
    .split(',')
    .map(cleanText)
    .filter(Boolean)
    .filter((part, index) => {
      if (index > 0) return true;
      return part.toLowerCase() !== lowerName;
    });

  return parts.slice(0, 4).join(', ');
};

const normalizedPlace = (item, center = null) => {
  const lat = finiteNumber(item?.lat);
  const lng = finiteNumber(item?.lon ?? item?.lng);
  const name = placeName(item);
  const address = cleanText(item?.display_name);
  const point =
    lat === null || lng === null ? null : { lat, lng };

  return {
    name: name || 'Place',
    label: name || address || 'Place',
    displayName: address || name || 'Place',
    address: address || name || 'Place',
    subtitle: placeSubtitle(item, name),
    type: cleanText(
      item?.type ||
        item?.category ||
        item?.addresstype ||
        'place',
    ),
    lat,
    lng,
    distanceM:
      center && point ? distanceM(center, point) : null,
    providerId: String(item?.place_id || item?.osm_id || ''),
  };
};

const dedupePlaces = (items) => {
  const seen = new Set();
  const output = [];

  for (const item of items) {
    if (
      !Number.isFinite(item.lat) ||
      !Number.isFinite(item.lng)
    ) {
      continue;
    }

    const key = [
      item.providerId,
      item.lat.toFixed(5),
      item.lng.toFixed(5),
      item.name.toLowerCase(),
    ].join('|');

    if (seen.has(key)) continue;
    seen.add(key);
    output.push(item);
  }

  return output;
};

const cacheGet = (key) => {
  const cached = searchCache.get(key);
  if (!cached) return null;
  if (Date.now() - cached.createdAt > CACHE_TTL_MS) {
    searchCache.delete(key);
    return null;
  }
  return structuredClone(cached.value);
};

const cacheSet = (key, value) => {
  searchCache.set(key, {
    createdAt: Date.now(),
    value: structuredClone(value),
  });

  if (searchCache.size > 250) {
    const first = searchCache.keys().next().value;
    searchCache.delete(first);
  }
};

const osmSearchUrl = (query, options = {}) => {
  const center = {
    lat: finiteNumber(options.lat, KALNA.lat),
    lng: finiteNumber(options.lng, KALNA.lng),
  };
  const latSpan = 0.26;
  const lngSpan = 0.32;
  const limit = clamp(
    finiteNumber(options.limit, 10),
    1,
    15,
  );

  const params = new URLSearchParams({
    format: 'jsonv2',
    q: query,
    limit: String(limit),
    countrycodes: 'in',
    addressdetails: '1',
    namedetails: '1',
    dedupe: '1',
    extratags: '1',
    'accept-language': options.language || 'bn,en',
    viewbox: [
      center.lng - lngSpan,
      center.lat + latSpan,
      center.lng + lngSpan,
      center.lat - latSpan,
    ].join(','),
    bounded: '0',
  });

  return `https://nominatim.openstreetmap.org/search?${params}`;
};

const osmHeaders = {
  'user-agent':
    'ASTRIDE/3.14 (local ride search; contact: kalnapolice@gmail.com)',
  accept: 'application/json',
};

const mappls = {
  async geocode(query, mode = 'test') {
    const c = cred('mappls', mode);
    if (mode === 'test' || !c.restApiKey) {
      return { provider: 'mappls', query, results: [] };
    }

    const data = await fetchJson(
      `https://atlas.mappls.com/api/places/geocode?address=${encodeURIComponent(query)}&itemCount=10`,
      {
        headers: {
          Authorization: `bearer ${c.restApiKey}`,
        },
      },
    );

    return {
      provider: 'mappls',
      query,
      results: (
        data.copResults ||
        data.suggestedLocations ||
        []
      ).map((item) => ({
        name: item.placeName || item.formattedAddress,
        label: item.placeName || item.formattedAddress,
        displayName: item.formattedAddress || item.placeName,
        address: item.formattedAddress,
        subtitle: item.formattedAddress,
        type: item.type || 'place',
        lat: Number(item.latitude),
        lng: Number(item.longitude),
        providerId: item.eLoc || item.mapplsPin,
      })),
    };
  },

  async reverse(point, mode = 'test') {
    if (mode === 'test') {
      return {
        provider: 'mappls',
        point,
        name: 'Pinned destination',
        displayName: 'Pinned destination',
        address: 'Pinned destination',
      };
    }

    return {
      provider: 'mappls',
      point,
      name: 'Pinned destination',
      displayName: 'Pinned destination',
      address: 'Pinned destination',
    };
  },

  async route(origin, destination, mode = 'test') {
    const c = cred('mappls', mode);
    if (mode === 'test' || !c.restApiKey) {
      return fallbackRoute('mappls', origin, destination);
    }

    const path =
      `${origin.lng},${origin.lat};` +
      `${destination.lng},${destination.lat}`;

    const data = await fetchJson(
      `https://apis.mappls.com/advancedmaps/v1/${encodeURIComponent(c.restApiKey)}/route_adv/driving/${path}?geometries=geojson&overview=full`,
    );

    const route = data.routes?.[0];
    if (!route) throw new Error('Mappls route unavailable');

    return {
      provider: 'mappls',
      origin,
      destination,
      distanceM: Math.round(route.distance),
      durationS: Math.round(route.duration),
      geometry: (route.geometry?.coordinates || []).map(
        ([lng, lat]) => ({ lat, lng }),
      ),
      estimated: false,
    };
  },
};

const google = {
  async geocode(query, mode = 'test', options = {}) {
    const c = cred('google', mode);
    if (mode === 'test' || !c.apiKey) {
      return { provider: 'google', query, results: [] };
    }

    const params = new URLSearchParams({
      address: query,
      key: c.apiKey,
      region: 'in',
      language: options.language === 'bn' ? 'bn' : 'en',
    });

    if (
      Number.isFinite(Number(options.lat)) &&
      Number.isFinite(Number(options.lng))
    ) {
      params.set(
        'bounds',
        `${Number(options.lat) - 0.25},${Number(options.lng) - 0.3}|` +
          `${Number(options.lat) + 0.25},${Number(options.lng) + 0.3}`,
      );
    }

    const data = await fetchJson(
      `https://maps.googleapis.com/maps/api/geocode/json?${params}`,
    );

    return {
      provider: 'google',
      query,
      results: (data.results || []).map((item) => ({
        name:
          item.address_components?.[0]?.long_name ||
          item.formatted_address,
        label:
          item.address_components?.[0]?.long_name ||
          item.formatted_address,
        displayName: item.formatted_address,
        address: item.formatted_address,
        subtitle: item.formatted_address,
        type: item.types?.[0] || 'place',
        lat: item.geometry.location.lat,
        lng: item.geometry.location.lng,
        providerId: item.place_id,
      })),
    };
  },

  async reverse(point, mode = 'test') {
    const c = cred('google', mode);
    if (mode === 'test' || !c.apiKey) {
      return {
        provider: 'google',
        point,
        name: 'Pinned destination',
        displayName: 'Pinned destination',
        address: 'Pinned destination',
      };
    }

    const params = new URLSearchParams({
      latlng: `${point.lat},${point.lng}`,
      key: c.apiKey,
      region: 'in',
    });

    const data = await fetchJson(
      `https://maps.googleapis.com/maps/api/geocode/json?${params}`,
    );

    const item = data.results?.[0];
    if (!item) throw new Error('Google reverse geocode unavailable');

    return {
      provider: 'google',
      point,
      name:
        item.address_components?.[0]?.long_name ||
        item.formatted_address,
      displayName: item.formatted_address,
      address: item.formatted_address,
      lat: point.lat,
      lng: point.lng,
      providerId: item.place_id,
    };
  },

  async route(origin, destination, mode = 'test') {
    const c = cred('google', mode);
    if (mode === 'test' || !c.apiKey) {
      return fallbackRoute('google', origin, destination);
    }

    const body = {
      origin: {
        location: {
          latLng: {
            latitude: origin.lat,
            longitude: origin.lng,
          },
        },
      },
      destination: {
        location: {
          latLng: {
            latitude: destination.lat,
            longitude: destination.lng,
          },
        },
      },
      travelMode: 'DRIVE',
      routingPreference: 'TRAFFIC_AWARE',
      polylineQuality: 'HIGH_QUALITY',
    };

    const data = await fetchJson(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-Goog-Api-Key': c.apiKey,
          'X-Goog-FieldMask':
            'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
        },
        body: JSON.stringify(body),
      },
    );

    const route = data.routes?.[0];
    if (!route) throw new Error('Google route unavailable');

    return {
      provider: 'google',
      origin,
      destination,
      distanceM: route.distanceMeters,
      durationS: Number(
        String(route.duration || '0s').replace('s', ''),
      ),
      encodedPolyline: route.polyline?.encodedPolyline,
      geometry: [origin, destination],
      estimated: false,
    };
  },
};

const osm = {
  async geocode(query, mode = 'test', options = {}) {
    const normalizedQuery = cleanText(query);
    if (mode === 'test') {
      return {
        provider: 'osm',
        query: normalizedQuery,
        results: [],
      };
    }

    const center = {
      lat: finiteNumber(options.lat, KALNA.lat),
      lng: finiteNumber(options.lng, KALNA.lng),
    };
    const cacheKey = JSON.stringify({
      query: normalizedQuery.toLowerCase(),
      lat: center.lat.toFixed(3),
      lng: center.lng.toFixed(3),
      language: options.language || 'bn,en',
      limit: options.limit || 10,
    });
    const cached = cacheGet(cacheKey);
    if (cached) return cached;

    const primary = await fetchJson(
      osmSearchUrl(normalizedQuery, {
        ...options,
        ...center,
      }),
      { headers: osmHeaders },
    );

    let merged = Array.isArray(primary) ? primary : [];
    const hasLocalContext =
      /(kalna|ambika|bardhaman|burdwan|পূর্ব বর্ধমান|কালনা)/i.test(
        normalizedQuery,
      );

    if (merged.length < 5 && !hasLocalContext) {
      const expanded =
        `${normalizedQuery}, Kalna, Purba Bardhaman, ` +
        'West Bengal, India';

      const secondary = await fetchJson(
        osmSearchUrl(expanded, {
          ...options,
          ...center,
        }),
        { headers: osmHeaders },
      );

      if (Array.isArray(secondary)) {
        merged = [...merged, ...secondary];
      }
    }

    const results = dedupePlaces(
      merged.map((item) => normalizedPlace(item, center)),
    )
      .sort((a, b) => {
        const aDistance =
          Number.isFinite(a.distanceM) ? a.distanceM : Infinity;
        const bDistance =
          Number.isFinite(b.distanceM) ? b.distanceM : Infinity;
        return aDistance - bDistance;
      })
      .slice(0, clamp(finiteNumber(options.limit, 10), 1, 15));

    const response = {
      provider: 'osm',
      query: normalizedQuery,
      searchCenter: center,
      results,
    };

    cacheSet(cacheKey, response);
    return response;
  },

  async reverse(point, mode = 'test', options = {}) {
    if (mode === 'test') {
      return {
        provider: 'osm',
        point,
        name: 'Pinned destination',
        displayName: 'Pinned destination',
        address: 'Pinned destination',
        lat: point.lat,
        lng: point.lng,
      };
    }

    const params = new URLSearchParams({
      format: 'jsonv2',
      lat: String(point.lat),
      lon: String(point.lng),
      zoom: '18',
      addressdetails: '1',
      namedetails: '1',
      'accept-language': options.language || 'bn,en',
    });

    const item = await fetchJson(
      `https://nominatim.openstreetmap.org/reverse?${params}`,
      { headers: osmHeaders },
    );

    const normalized = normalizedPlace(item, point);

    return {
      provider: 'osm',
      point,
      ...normalized,
      lat: point.lat,
      lng: point.lng,
    };
  },

  async route(origin, destination, mode = 'test') {
    if (mode === 'test') {
      return fallbackRoute('osm', origin, destination);
    }

    const data = await fetchJson(
      `https://router.project-osrm.org/route/v1/driving/` +
        `${origin.lng},${origin.lat};` +
        `${destination.lng},${destination.lat}` +
        '?overview=full&geometries=geojson',
    );

    const route = data.routes?.[0];
    if (!route) throw new Error('OSM route unavailable');

    return {
      provider: 'osm',
      origin,
      destination,
      distanceM: Math.round(route.distance),
      durationS: Math.round(route.duration),
      geometry: (route.geometry?.coordinates || []).map(
        ([lng, lat]) => ({ lat, lng }),
      ),
      estimated: false,
    };
  },
};

const adapters = { mappls, google, osm };

export function getMapAdapter(name) {
  const adapter = adapters[name];
  if (!adapter) {
    throw new Error(`Unsupported map provider: ${name}`);
  }
  return adapter;
}
