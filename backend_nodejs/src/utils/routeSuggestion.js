const Route = require('../models/Route');

const toRadians = (value) => (value * Math.PI) / 180;

const distanceInKilometres = (from, to) => {
  const earthRadius = 6371;
  const latDistance = toRadians(to.lat - from.lat);
  const lngDistance = toRadians(to.lng - from.lng);
  const a =
    Math.sin(latDistance / 2) ** 2 +
    Math.cos(toRadians(from.lat)) *
      Math.cos(toRadians(to.lat)) *
      Math.sin(lngDistance / 2) ** 2;

  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

const validCoordinates = (coordinates) => (
  coordinates &&
  Number.isFinite(Number(coordinates.lat)) &&
  Number.isFinite(Number(coordinates.lng))
);

const findSuggestedRoute = async ({ location, coordinates, date }) => {
  const routes = await Route.find({
    status: { $in: ['draft', 'assigned', 'in-progress'] },
    ...(date ? { date: { $gte: new Date(date) } } : {}),
  }).select('routeName zone description assignedLocations areaCoordinates assignedDriver date');

  if (!routes.length) return null;

  const normalizedLocation = String(location || '').toLowerCase();
  const requestCoordinates = validCoordinates(coordinates)
    ? { lat: Number(coordinates.lat), lng: Number(coordinates.lng) }
    : null;

  const scoredRoutes = routes.map((route) => {
    const matchingArea = [route.zone, ...(route.assignedLocations || [])]
      .some((area) => normalizedLocation.includes(String(area).toLowerCase()));

    const routeCoordinates = route.areaCoordinates;
    const distance = requestCoordinates && validCoordinates(routeCoordinates)
      ? distanceInKilometres(requestCoordinates, routeCoordinates)
      : null;

    return {
      route,
      distance,
      matchingArea,
    };
  });

  scoredRoutes.sort((left, right) => {
    if (left.matchingArea !== right.matchingArea) {
      return left.matchingArea ? -1 : 1;
    }

    if (left.distance !== null && right.distance !== null) {
      return left.distance - right.distance;
    }

    if (left.distance !== null) return -1;
    if (right.distance !== null) return 1;
    return 0;
  });

  const selected = scoredRoutes[0];
  if (!selected.matchingArea && selected.distance === null) {
    return null;
  }

  return {
    route: selected.route,
    distanceKm: selected.distance,
    reason: selected.matchingArea
      ? 'Pickup location matches the route area'
      : selected.distance !== null
        ? 'Route has the closest configured area coordinates'
        : 'Route area is the closest available text match',
  };
};

module.exports = {
  findSuggestedRoute,
};
