const Bus = require('../models/Bus');

// @desc    Get all buses
// @route   GET /api/buses
// @access  Public
const getAllBuses = async (req, res) => {
  try {
    const buses = await Bus.getAllBuses();
    res.json(buses);
  } catch (error) {
    console.error('Error fetching all buses:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Search buses
// @route   GET /api/buses/search
// @access  Public
const searchBuses = async (req, res) => {
  try {
    const { source, destination, date } = req.query;
    const buses = await Bus.searchBuses(source, destination, date);
    res.json(buses);
  } catch (error) {
    console.error('Error searching buses:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get bus by route ID
// @route   GET /api/buses/:id
// @access  Public
const getBusById = async (req, res) => {
  try {
    const bus = await Bus.getBusById(req.params.id);
    if (!bus) {
      return res.status(404).json({ message: 'Bus not found' });
    }
    res.json(bus);
  } catch (error) {
    console.error('Error fetching bus:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Create new bus/route
// @route   POST /api/buses
// @access  Private/Admin
const createBus = async (req, res) => {
  try {
    const routeId = await Bus.createRoute(req.body);
    res.status(201).json({ message: 'Bus created successfully', routeId });
  } catch (error) {
    console.error('Error creating bus:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Update bus/route
// @route   PUT /api/buses/:id
// @access  Private/Admin
const updateBus = async (req, res) => {
  try {
    const success = await Bus.updateRoute(req.params.id, req.body);
    if (!success) {
      return res.status(404).json({ message: 'Bus not found' });
    }
    res.json({ message: 'Bus updated successfully' });
  } catch (error) {
    console.error('Error updating bus:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Delete bus/route
// @route   DELETE /api/buses/:id
// @access  Private/Admin
const deleteBus = async (req, res) => {
  try {
    const success = await Bus.deleteRoute(req.params.id);
    if (!success) {
      return res.status(404).json({ message: 'Bus not found' });
    }
    res.json({ message: 'Bus deleted successfully' });
  } catch (error) {
    console.error('Error deleting bus:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const POPULAR_CITIES = [
  'Hyderabad',
  'Vijayawada',
  'Visakhapatnam',
  'Tirupati',
  'Guntur',
  'Kurnool',
  'Nellore',
  'Kadapa',
  'Rajahmundry',
  'Kakinada',
  'Anantapur',
  'Ongole',
  'Warangal',
  'Chittoor',
  'Eluru',
  'Srikakulam',
  'Vizianagaram',
  'Secunderabad',
  'Nandyal',
  'Madanapalle'
];

// @desc    Get all distinct route cities
// @route   GET /api/buses/cities
// @access  Public
const getCities = async (req, res) => {
  try {
    const dbCities = await Bus.getCities();
    const set = new Set();
    const result = [];

    // Prioritize DB cities
    for (const city of dbCities) {
      const lower = city.toLowerCase();
      if (!set.has(lower)) {
        set.add(lower);
        result.push(city);
      }
    }

    // Add popular cities
    for (const city of POPULAR_CITIES) {
      const lower = city.toLowerCase();
      if (!set.has(lower)) {
        set.add(lower);
        result.push(city);
      }
    }

    res.json(result.sort((a, b) => a.localeCompare(b)));
  } catch (error) {
    console.error('Error fetching cities:', error);
    res.json(POPULAR_CITIES.sort((a, b) => a.localeCompare(b)));
  }
};

// @desc    Get intermediate stops for a route
// @route   GET /api/buses/:id/stops
// @access  Public
const getRouteStops = async (req, res) => {
  try {
    const stops = await Bus.getRouteStops(req.params.id);
    res.json(stops);
  } catch (error) {
    console.error('Error fetching route stops:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  getAllBuses,
  searchBuses,
  getCities,
  getBusById,
  getRouteStops,
  createBus,
  updateBus,
  deleteBus
};
