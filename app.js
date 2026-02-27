// Data Service
class DataService {
    constructor() {
        this.trips = JSON.parse(localStorage.getItem('trips') || '[]');
        this.markers = JSON.parse(localStorage.getItem('markers') || '[]');
        this.images = JSON.parse(localStorage.getItem('images') || '[]');
        this.nextTripId = parseInt(localStorage.getItem('nextTripId') || '1');
        this.nextMarkerId = parseInt(localStorage.getItem('nextMarkerId') || '1');
        this.nextImageId = parseInt(localStorage.getItem('nextImageId') || '1');
    }

    save() {
        localStorage.setItem('trips', JSON.stringify(this.trips));
        localStorage.setItem('markers', JSON.stringify(this.markers));
        localStorage.setItem('images', JSON.stringify(this.images));
        localStorage.setItem('nextTripId', this.nextTripId.toString());
        localStorage.setItem('nextMarkerId', this.nextMarkerId.toString());
        localStorage.setItem('nextImageId', this.nextImageId.toString());
    }

    // Trip operations
    getAllTrips() {
        return this.trips.sort((a, b) => a.displayOrder - b.displayOrder);
    }

    getTripById(id) {
        return this.trips.find(t => t.id === id);
    }

    createTrip(name) {
        const trip = {
            id: this.nextTripId++,
            name,
            coverImagePath: null,
            createdAt: new Date().toISOString(),
            startDate: null,
            endDate: null,
            displayOrder: this.trips.length
        };
        this.trips.push(trip);
        this.save();
        return trip;
    }

    updateTrip(id, name) {
        const trip = this.getTripById(id);
        if (trip) {
            trip.name = name;
            this.save();
        }
        return trip;
    }

    deleteTrip(id) {
        this.trips = this.trips.filter(t => t.id !== id);
        this.markers = this.markers.filter(m => m.tripId !== id);
        // Delete images for this trip's markers
        const markerIds = this.markers.filter(m => m.tripId === id).map(m => m.id);
        this.images = this.images.filter(img => !markerIds.includes(img.markerId));
        this.save();
    }

    getMarkerCount(tripId) {
        return this.markers.filter(m => m.tripId === tripId).length;
    }

    // Update trip cover from first marker's first image
    updateTripCover(tripId) {
        const markers = this.getMarkersByTripId(tripId);
        for (const marker of markers) {
            const images = this.getImagesByMarkerId(marker.id);
            if (images.length > 0) {
                const trip = this.getTripById(tripId);
                if (trip) {
                    trip.coverImagePath = images[0].dataUrl;
                    this.save();
                }
                return;
            }
        }
    }

    // Marker operations
    getMarkersByTripId(tripId) {
        return this.markers
            .filter(m => m.tripId === tripId)
            .sort((a, b) => a.displayOrder - b.displayOrder);
    }

    getMarkerById(id) {
        return this.markers.find(m => m.id === id);
    }

    createMarker(tripId, latitude, longitude, title, address) {
        const tripMarkers = this.getMarkersByTripId(tripId);
        const marker = {
            id: this.nextMarkerId++,
            tripId,
            title,
            address,
            latitude,
            longitude,
            notes: null,
            link: null,
            imagePaths: [],
            color: '#F44336',
            icon: 'default',
            category: null,
            displayOrder: tripMarkers.length,
            createdAt: new Date().toISOString()
        };
        this.markers.push(marker);
        this.save();
        return marker;
    }

    updateMarker(id, updates) {
        const marker = this.getMarkerById(id);
        if (marker) {
            Object.assign(marker, updates);
            this.save();
        }
        return marker;
    }

    deleteMarker(id) {
        // Delete images for this marker
        this.images = this.images.filter(img => img.markerId !== id);
        this.markers = this.markers.filter(m => m.id !== id);
        this.save();
    }

    clearMarkersByTripId(tripId) {
        const markerIds = this.markers.filter(m => m.tripId === tripId).map(m => m.id);
        this.images = this.images.filter(img => !markerIds.includes(img.markerId));
        this.markers = this.markers.filter(m => m.tripId !== tripId);
        this.save();
    }

    // Image operations
    getImagesByMarkerId(markerId) {
        return this.images
            .filter(img => img.markerId === markerId)
            .sort((a, b) => a.displayOrder - b.displayOrder);
    }

    addImage(markerId, dataUrl) {
        const markerImages = this.getImagesByMarkerId(markerId);
        const image = {
            id: this.nextImageId++,
            markerId,
            dataUrl,
            displayOrder: markerImages.length,
            createdAt: new Date().toISOString()
        };
        this.images.push(image);
        this.save();
        return image;
    }

    deleteImage(imageId) {
        this.images = this.images.filter(img => img.id !== imageId);
        // Reorder remaining images
        const markerId = this.images.find(img => img.id === imageId)?.markerId;
        if (markerId) {
            const markerImages = this.getImagesByMarkerId(markerId);
            markerImages.forEach((img, index) => {
                img.displayOrder = index;
            });
        }
        this.save();
    }

    clearAll() {
        this.trips = [];
        this.markers = [];
        this.images = [];
        this.save();
    }

    addDemoData() {
        // Create a demo trip
        const trip = this.createTrip('示例行程 - 北京之旅');

        // Create demo markers - using locations closer to center
        const marker1 = this.createMarker(trip.id, 39.9042, 116.4074, '天安门广场', '北京市东城区西长安街');
        const marker2 = this.createMarker(trip.id, 39.9163, 116.3972, '故宫博物院', '北京市东城区景山前街4号');
        const marker3 = this.createMarker(trip.id, 39.9080, 116.3975, '北海公园', '北京市西城区文津街1号');
        const marker4 = this.createMarker(trip.id, 39.9250, 116.4070, '南锣鼓巷', '北京市东城区南锣鼓巷');
        const marker5 = this.createMarker(trip.id, 39.8950, 116.4180, '天坛公园', '北京市东城区天坛东里甲1号');

        // Add demo notes and custom styles
        this.updateMarker(marker1.id, { notes: '中国首都的标志性建筑，必游景点！' });
        this.updateMarker(marker2.id, { notes: '明清两代的皇家宫殿，世界文化遗产' });
        this.updateMarker(marker3.id, { color: '#2196F3', notes: '中国现存最古老、最完整的皇家园林之一' });
        this.updateMarker(marker4.id, { color: '#FF9800', notes: '北京最古老的街区之一，特色小吃云集' });
        this.updateMarker(marker5.id, { color: '#9C27B0', notes: '明清两代皇帝祭祀皇天、祈五谷丰登的场所' });
    }
}

// App State
const dataService = new DataService();
let currentTrip = null;
let selectedMarker = null;
let uploadedImages = [];
let currentPreviewIndex = 0;
let previewImages = [];
let selectedMarkerColor = '#F44336';

// Map state
let mapOffsetX = 0;
let mapOffsetY = 0;
let mapZoom = 1.0;
let isDragging = false;
let dragStartX = 0;
let dragStartY = 0;
let showRoutes = false;
let amap = null; // AMap instance
let amapMarkers = []; // AMap markers storage
let amapPolylines = []; // AMap polylines storage
let autoComplete = null; // AutoComplete instance
let placeSearch = null; // PlaceSearch instance
let searchTimeout = null; // Debounce timer
let trafficLayer = null; // Traffic layer instance
let showTraffic = false; // Traffic visibility state

const defaultIconSvg = '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>';

// Category colors
const categoryColors = {
    '景点': '#FF5722',
    '美食': '#FF9800',
    '住宿': '#795548',
    '交通': '#607D8B',
    '购物': '#E91E63',
    '自然': '#4CAF50',
    '文化': '#9C27B0',
    '其他': '#9E9E9E'
};

function getCategoryColor(category) {
    return categoryColors[category] || '#9E9E9E';
}

// DOM Elements
const tripListView = document.getElementById('tripListView');
const mapView = document.getElementById('mapView');
const tripList = document.getElementById('tripList');
const emptyState = document.getElementById('emptyState');
const mapElement = document.getElementById('map');
const mapTitle = document.getElementById('mapTitle');
const markerCount = document.getElementById('markerCount');
const markerInfo = document.getElementById('markerInfo');
const addMarkerHint = document.getElementById('addMarkerHint');
const fab = document.getElementById('fab');
const dialogOverlay = document.getElementById('dialogOverlay');
const tripDialog = document.getElementById('tripDialog');
const markerDialog = document.getElementById('markerDialog');
const markerListSheet = document.getElementById('markerListSheet');
const imagePreviewModal = document.getElementById('imagePreviewModal');
const previewImage = document.getElementById('previewImage');
const searchInput = document.getElementById('searchInput');
const searchResults = document.getElementById('searchResults');
const searchClear = document.getElementById('searchClear');

// Initialize
function init() {
    renderTripList();
    setupEventListeners();

    // Check if AMap is loaded
    if (typeof AMap !== 'undefined') {
        initAMap();
    } else {
        // Wait for AMap to load
        window.addEventListener('load', () => {
            if (typeof AMap !== 'undefined') {
                initAMap();
            } else {
                console.error('AMap SDK failed to load. Please check your API key.');
                // Fallback to mock map
                renderMockMap();
            }
        });
    }
}

// Initialize AMap
function initAMap() {
    console.log('Initializing AMap...');
    try {
        amap = new AMap.Map('map', {
            zoom: 13,
            center: [116.397428, 39.90923],
            viewMode: '2D',
            showLabel: true,
            // 显示地图要素：道路、建筑、POI点位
            features: ['bg', 'road', 'building', 'point'],
            // 使用标准样式显示完整地图信息
            mapStyle: 'amap://styles/normal',
            // 显示默认的地图控件
            showIndoorMap: false,
            rotateEnable: false,
            pitchEnable: false
        });

        // Initialize AutoComplete and PlaceSearch
        AMap.plugin(['AMap.AutoComplete', 'AMap.PlaceSearch'], () => {
            autoComplete = new AMap.AutoComplete({
                city: '全国'
            });

            placeSearch = new AMap.PlaceSearch({
                city: '全国',
                pageSize: 20,
                pageIndex: 1,
                extensions: 'all',
                type: '',
                autoFitView: false
            });

            console.log('Search plugins initialized');
        });

        // Initialize Traffic Layer
        AMap.plugin(['AMap.TileLayer.Traffic'], () => {
            trafficLayer = new AMap.TileLayer.Traffic({
                zIndex: 10,
                autoRefresh: true // 自动刷新交通数据
            });
            console.log('Traffic layer initialized');
        });

        // Map click listener for adding markers
        amap.on('click', (e) => {
            const lnglat = e.lnglat;
            addMarker(lnglat.lat, lnglat.lng);
        });

        console.log('AMap initialized successfully');
    } catch (error) {
        console.error('Failed to initialize AMap:', error);
        // Don't call renderMockMap here, it will be called when entering map view
    }
}

// Setup Event Listeners
function setupEventListeners() {
    document.getElementById('refreshBtn').addEventListener('click', renderTripList);
    document.getElementById('clearAllBtn').addEventListener('click', () => {
        if (confirm('确定要清空所有数据吗？')) {
            dataService.clearAll();
            renderTripList();
        }
    });

    // Color picker
    document.getElementById('colorPicker').addEventListener('click', (e) => {
        if (e.target.classList.contains('color-option')) {
            document.querySelectorAll('.color-option').forEach(el => {
                el.classList.remove('selected');
            });
            e.target.classList.add('selected');
            selectedMarkerColor = e.target.dataset.color;
        }
    });

    // Keyboard navigation for image preview
    document.addEventListener('keydown', (e) => {
        if (imagePreviewModal.style.display === 'flex') {
            if (e.key === 'ArrowLeft') prevImage();
            if (e.key === 'ArrowRight') nextImage();
            if (e.key === 'Escape') closeImagePreview();
        }
    });

    // Search input events
    searchInput.addEventListener('input', (e) => {
        const keyword = e.target.value.trim();
        console.log('Search input changed:', keyword);

        // Show/hide clear button
        searchClear.style.display = keyword ? 'flex' : 'none';

        if (keyword.length > 0) {
            // Debounce autoComplete search
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                console.log('Triggering autoComplete search for:', keyword);
                performAutoCompleteSearch(keyword);
            }, 300);
        } else {
            searchResults.style.display = 'none';
        }
    });

    // Hide search results when clicking outside
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.map-search-container')) {
            searchResults.style.display = 'none';
        }
    });

    // Search on Enter key - use full POI search
    searchInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            const keyword = e.target.value.trim();
            if (keyword) {
                performSearch(keyword);
            }
        }
    });
}

// Render Trip List
function renderTripList() {
    const trips = dataService.getAllTrips();

    if (trips.length === 0) {
        tripList.style.display = 'none';
        emptyState.style.display = 'block';
        return;
    }

    tripList.style.display = 'flex';
    emptyState.style.display = 'none';

    tripList.innerHTML = trips.map(trip => {
        const markerCount = dataService.getMarkerCount(trip.id);

        // Get cover image (first image of first marker)
        let coverHtml = '<div class="trip-cover">🗺️</div>';
        const markers = dataService.getMarkersByTripId(trip.id);
        for (const marker of markers) {
            const images = dataService.getImagesByMarkerId(marker.id);
            if (images.length > 0) {
                coverHtml = `<div class="trip-cover"><img src="${images[0].dataUrl}" class="trip-cover-img" alt="封面"></div>`;
                break;
            }
        }

        return `
            <div class="trip-card" onclick="openTrip(${trip.id})">
                ${coverHtml}
                <div class="trip-info">
                    <h3>${escapeHtml(trip.name)}</h3>
                    <div class="trip-meta">
                        <span>📍 ${markerCount} 个标记</span>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

// Show Trip List
function showTripList() {
    tripListView.style.display = 'block';
    mapView.style.display = 'none';
    fab.style.display = 'flex';
    currentTrip = null;
    selectedMarker = null;
    uploadedImages = [];
    // Reset map state
    mapOffsetX = 0;
    mapOffsetY = 0;
    mapZoom = 1.0;
    renderTripList();
}

// Open Trip
function openTrip(tripId) {
    currentTrip = dataService.getTripById(tripId);
    mapTitle.textContent = currentTrip.name;
    tripListView.style.display = 'none';
    mapView.style.display = 'block';
    fab.style.display = 'none';
    // Reset map state
    mapOffsetX = 0;
    mapOffsetY = 0;
    mapZoom = 1.0;
    showRoutes = false;
    // Reset route toggle button style
    const btn = document.getElementById('routeToggleBtn');
    if (btn) {
        btn.style.background = '';
        btn.style.color = '';
    }
    renderMap();
    // Auto-fit markers after a short delay to ensure map is visible
    setTimeout(() => fitAllMarkers(), 100);
}


// Render Map
function renderMap() {
    // Use AMap if available, otherwise use mock map
    if (amap) {
        renderAMap();
    } else {
        renderMockMap();
    }
}

// Render markers on AMap
function renderAMap() {
    // Clear existing markers and polylines
    amapMarkers.forEach(marker => amap.remove(marker));
    amapMarkers = [];
    amapPolylines.forEach(polyline => amap.remove(polyline));
    amapPolylines = [];

    const markers = dataService.getMarkersByTripId(currentTrip.id);

    // Update marker count
    markerCount.textContent = markers.length;

    // Show/hide add hint
    addMarkerHint.style.display = markers.length === 0 ? 'block' : 'none';

    // Create AMap markers
    markers.forEach((marker, index) => {
        const content = `
            <div style="
                background: ${marker.color || '#F44336'};
                width: 32px;
                height: 32px;
                border-radius: 50% 50% 50% 0;
                transform: rotate(-45deg);
                display: flex;
                align-items: center;
                justify-content: center;
                box-shadow: 0 2px 8px rgba(0,0,0,0.3);
                position: relative;
            ">
                <svg viewBox="0 0 24 24" fill="white" style="width: 18px; height: 18px; transform: rotate(45deg);">
                    ${defaultIconSvg}
                </svg>
            </div>
            <div style="
                position: absolute;
                top: -28px;
                left: 50%;
                transform: translateX(-50%);
                background: white;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 12px;
                white-space: nowrap;
                box-shadow: 0 1px 4px rgba(0,0,0,0.2);
                font-weight: 500;
            ">${escapeHtml(marker.title)}</div>
        `;

        const amapMarker = new AMap.Marker({
            position: [marker.longitude, marker.latitude],
            content: content,
            offset: new AMap.Pixel(-16, -32),
            title: marker.title,
            extData: { id: marker.id }
        });

        amapMarker.on('click', () => {
            selectMarker(marker);
        });

        amapMarker.setMap(amap);
        amapMarkers.push(amapMarker);
    });

    // Draw routes if enabled
    if (showRoutes && markers.length > 1) {
        const path = markers.map(m => [m.longitude, m.latitude]);

        const polyline = new AMap.Polyline({
            path: path,
            borderWeight: 3,
            strokeColor: '#2196F3',
            lineJoin: 'round',
            strokeStyle: 'dashed',
            strokeOpacity: 0.7,
            showDir: true
        });

        polyline.setMap(amap);
        amapPolylines.push(polyline);
    }

    // Fit markers in view
    if (markers.length > 0) {
        const bounds = new AMap.Bounds();
        markers.forEach(m => {
            bounds.extend([m.longitude, m.latitude]);
        });
        amap.setFitView();
    }
}

// Render mock map (fallback)
function renderMockMap() {
    // Check if currentTrip exists
    if (!currentTrip || !currentTrip.id) {
        return;
    }

    // Clear existing markers and routes (but keep background roads)
    const existingMarkers = mapElement.querySelectorAll('.map-marker');
    existingMarkers.forEach(m => m.remove());
    const existingRoutes = mapElement.querySelectorAll('.map-routes');
    existingRoutes.forEach(r => r.remove());

    const markers = dataService.getMarkersByTripId(currentTrip.id);

    // Update marker count
    markerCount.textContent = markers.length;

    // Show/hide add hint
    addMarkerHint.style.display = markers.length === 0 ? 'block' : 'none';

    // Render markers
    const mapRect = mapElement.getBoundingClientRect();
    const centerX = mapRect.width / 2;
    const centerY = mapRect.height / 2;

    markers.forEach((marker, index) => {
        const markerEl = document.createElement('div');
        markerEl.className = 'map-marker';
        markerEl.dataset.id = marker.id;

        // Calculate position (simple offset from center based on coords)
        const baseOffsetX = (marker.longitude - 116.4074) * 10000;
        const baseOffsetY = (marker.latitude - 39.9042) * 10000;

        // Apply map transform
        const finalX = centerX + (baseOffsetX * mapZoom) + mapOffsetX;
        const finalY = centerY + (baseOffsetY * mapZoom) + mapOffsetY;

        markerEl.style.left = finalX + 'px';
        markerEl.style.top = finalY + 'px';

        // Get marker color
        const color = marker.color || '#F44336';

        markerEl.innerHTML = `
            <div class="map-marker-icon" style="background: ${color};">
                <svg viewBox="0 0 24 24" fill="white">
                    ${defaultIconSvg}
                </svg>
            </div>
            <div class="map-marker-label">${escapeHtml(marker.title)}</div>
        `;

        markerEl.addEventListener('click', (e) => {
            e.stopPropagation();
            selectMarker(marker);
        });

        mapElement.appendChild(markerEl);
    });

    // Draw routes between markers
    if (showRoutes && markers.length > 1) {
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('class', 'map-routes');
        svg.style.position = 'absolute';
        svg.style.top = '0';
        svg.style.left = '0';
        svg.style.width = '100%';
        svg.style.height = '100%';
        svg.style.pointerEvents = 'none';
        svg.style.overflow = 'visible';

        // Get marker positions
        const markerPositions = markers.map(marker => {
            const baseOffsetX = (marker.longitude - 116.4074) * 10000;
            const baseOffsetY = (marker.latitude - 39.9042) * 10000;
            return {
                x: centerX + (baseOffsetX * mapZoom) + mapOffsetX,
                y: centerY + (baseOffsetY * mapZoom) + mapOffsetY
            };
        });

        // Draw lines between consecutive markers
        for (let i = 0; i < markerPositions.length - 1; i++) {
            const start = markerPositions[i];
            const end = markerPositions[i + 1];

            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', start.x);
            line.setAttribute('y1', start.y);
            line.setAttribute('x2', end.x);
            line.setAttribute('y2', end.y);
            line.setAttribute('stroke', '#2196F3');
            line.setAttribute('stroke-width', '3');
            line.setAttribute('stroke-linecap', 'round');
            line.setAttribute('stroke-dasharray', '8,4');
            line.style.opacity = '0.7';

            svg.appendChild(line);

            // Add direction arrow
            const angle = Math.atan2(end.y - start.y, end.x - start.x);
            const midX = (start.x + end.x) / 2;
            const midY = (start.y + end.y) / 2;
            const arrowSize = 8;

            const arrow = document.createElementNS('http://www.w3.org/2000/svg', 'polygon');
            const arrowPoints = [
                { x: midX + arrowSize * Math.cos(angle), y: midY + arrowSize * Math.sin(angle) },
                { x: midX + arrowSize * Math.cos(angle + 2.5), y: midY + arrowSize * Math.sin(angle + 2.5) },
                { x: midX + arrowSize * Math.cos(angle - 2.5), y: midY + arrowSize * Math.sin(angle - 2.5) }
            ];

            arrow.setAttribute('points', arrowPoints.map(p => `${p.x},${p.y}`).join(' '));
            arrow.setAttribute('fill', '#2196F3');
            arrow.style.opacity = '0.7';

            svg.appendChild(arrow);
        }

        mapElement.appendChild(svg);
    }

    // Setup map drag
    setupMapDrag();

    // Map click to add marker
    mapElement.onclick = (e) => {
        if (e.target === mapElement) {
            const rect = mapElement.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            // Convert to mock coordinates (accounting for map offset and zoom)
            const adjustedX = (x - centerX - mapOffsetX) / mapZoom;
            const adjustedY = (y - centerY - mapOffsetY) / mapZoom;
            const lat = 39.9042 + adjustedY / 10000;
            const lng = 116.4074 + adjustedX / 10000;

            addMarker(lat, lng);
        }
    };
}

// Setup map drag functionality
function setupMapDrag() {
    mapElement.onmousedown = (e) => {
        if (e.target === mapElement || e.target.classList.contains('map-marker')) {
            isDragging = true;
            dragStartX = e.clientX - mapOffsetX;
            dragStartY = e.clientY - mapOffsetY;
            mapElement.style.cursor = 'grabbing';
            e.preventDefault();
        }
    };

    document.onmousemove = (e) => {
        if (isDragging) {
            mapOffsetX = e.clientX - dragStartX;
            mapOffsetY = e.clientY - dragStartY;
            renderMap();
        }
    };

    document.onmouseup = () => {
        if (isDragging) {
            isDragging = false;
            mapElement.style.cursor = 'grab';
        }
    };
}

// Zoom in
function zoomIn() {
    if (amap) {
        amap.zoomIn();
    } else {
        mapZoom = Math.min(mapZoom + 0.2, 3.0);
        renderMap();
    }
}

// Zoom out
function zoomOut() {
    if (amap) {
        amap.zoomOut();
    } else {
        mapZoom = Math.max(mapZoom - 0.2, 0.3);
        renderMap();
    }
}

// Toggle routes display
function toggleRoutes() {
    showRoutes = !showRoutes;
    const btn = document.getElementById('routeToggleBtn');
    if (btn) {
        btn.style.background = showRoutes ? 'var(--primary-light)' : '';
        btn.style.color = showRoutes ? 'var(--primary)' : '';
    }
    renderMap();
}

// Toggle traffic layer
function toggleTraffic() {
    showTraffic = !showTraffic;
    const btn = document.getElementById('trafficToggleBtn');
    if (btn) {
        btn.style.background = showTraffic ? 'var(--primary-light)' : '';
        btn.style.color = showTraffic ? 'var(--primary)' : '';
    }

    if (amap && trafficLayer) {
        if (showTraffic) {
            amap.add(trafficLayer);
        } else {
            amap.remove(trafficLayer);
        }
    }
}

// Fit all markers in view
function fitAllMarkers() {
    if (amap) {
        amap.setFitView();
    } else {
        const markers = dataService.getMarkersByTripId(currentTrip.id);
        if (markers.length === 0) {
            // Reset to center if no markers
            mapOffsetX = 0;
            mapOffsetY = 0;
            mapZoom = 1.0;
            renderMap();
            return;
        }

        // Calculate bounding box
        let minLat = markers[0].latitude;
        let maxLat = markers[0].latitude;
        let minLng = markers[0].longitude;
        let maxLng = markers[0].longitude;

        markers.forEach(m => {
            minLat = Math.min(minLat, m.latitude);
            maxLat = Math.max(maxLat, m.latitude);
            minLng = Math.min(minLng, m.longitude);
            maxLng = Math.max(maxLng, m.longitude);
        });

        // Calculate center
        const centerLat = (minLat + maxLat) / 2;
        const centerLng = (minLng + maxLng) / 2;

        // Calculate required zoom
        const latDiff = maxLat - minLat;
        const lngDiff = maxLng - minLng;
        const maxDiff = Math.max(latDiff, lngDiff, 0.001); // Minimum diff to avoid division by zero

        // Base zoom calculation (adjust multiplier as needed)
        const mapRect = mapElement.getBoundingClientRect();
        const minDimension = Math.min(mapRect.width, mapRect.height);
        const targetSize = minDimension * 0.6; // Use 60% of map size
        const newZoom = (targetSize / 10000) / maxDiff;

        mapZoom = Math.min(Math.max(newZoom, 0.3), 3.0);

        // Calculate offset to center the bounding box
        const centerXOffset = (centerLng - 116.4074) * 10000 * mapZoom;
        const centerYOffset = (centerLat - 39.9042) * 10000 * mapZoom;
        mapOffsetX = -centerXOffset;
        mapOffsetY = -centerYOffset;

        renderMap();
    }
}

// Select Marker
function selectMarker(marker) {
    selectedMarker = marker;

    // Zoom and center map to marker location
    if (amap) {
        // Use real AMap
        amap.setCenter([marker.longitude, marker.latitude]);
        amap.setZoom(16);
    } else {
        // Use mock map - adjust offset and zoom
        const mapRect = mapElement.getBoundingClientRect();
        const centerX = mapRect.width / 2;
        const centerY = mapRect.height / 2;

        // Calculate current offset to center the marker
        const baseOffsetX = (marker.longitude - 116.4074) * 10000;
        const baseOffsetY = (marker.latitude - 39.9042) * 10000;

        // Reset to center the marker
        mapOffsetX = -baseOffsetX;
        mapOffsetY = -baseOffsetY;
        mapZoom = 3;

        // Re-render map with new position
        renderMockMap();
    }

    // Update visual selection
    document.querySelectorAll('.map-marker').forEach(el => {
        el.classList.toggle('selected', parseInt(el.dataset.id) === marker.id);
    });

    // Show marker info
    document.getElementById('markerInfoTitle').textContent = marker.title;
    document.getElementById('markerInfoAddress').textContent = marker.address;
    document.getElementById('markerInfoCoords').textContent =
        `${marker.latitude.toFixed(6)}, ${marker.longitude.toFixed(6)}`;

    const notesEl = document.getElementById('markerInfoNotes');
    if (marker.notes) {
        notesEl.textContent = marker.notes;
        notesEl.style.display = 'block';
    } else {
        notesEl.style.display = 'none';
    }

    const linkEl = document.getElementById('markerInfoLink');
    if (marker.link) {
        linkEl.innerHTML = `<a href="${escapeHtml(marker.link)}" target="_blank">🔗 ${escapeHtml(marker.link)}</a>`;
        linkEl.style.display = 'block';
    } else {
        linkEl.style.display = 'none';
    }

    // Show images
    const imagesSection = document.getElementById('markerImagesSection');
    const imagesGrid = document.getElementById('markerImages');
    const images = dataService.getImagesByMarkerId(marker.id);

    if (images.length > 0) {
        document.getElementById('imageCount').textContent = images.length;
        imagesGrid.innerHTML = images.map((img, index) => `
            <div class="marker-image-item" onclick="openImagePreview(${marker.id}, ${index})">
                <img src="${img.dataUrl}" alt="图片 ${index + 1}">
            </div>
        `).join('');
        imagesSection.style.display = 'block';
    } else {
        imagesSection.style.display = 'none';
    }

    markerInfo.style.display = 'block';
}

// Close Marker Info
function closeMarkerInfo() {
    selectedMarker = null;
    markerInfo.style.display = 'none';
    document.querySelectorAll('.map-marker').forEach(el => {
        el.classList.remove('selected');
    });
}

// Add Marker
function addMarker(latitude, longitude, providedTitle = null, providedAddress = null) {
    // If title and address are provided (from search), use them directly
    if (providedTitle && providedAddress) {
        const marker = dataService.createMarker(
            currentTrip.id,
            latitude,
            longitude,
            providedTitle,
            providedAddress
        );
        renderMap();
        selectMarker(marker);
        return;
    }

    // Try to get address using AMap Geocoding
    if (amap && typeof AMap !== 'undefined' && AMap.Geocoder) {
        const geocoder = new AMap.Geocoder();
        geocoder.getAddress([longitude, latitude], (status, result) => {
            let address = `纬度: ${latitude.toFixed(4)}, 经度: ${longitude.toFixed(4)}`;
            let title = `位置 ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;

            if (status === 'complete' && result && result.regeocode) {
                address = result.regeocode.formattedAddress;
                // Use a shorter title from the address
                if (result.regeocode.aois && result.regeocode.aois.length > 0) {
                    title = result.regeocode.aois[0].name;
                } else if (result.regeocode.pois && result.regeocode.pois.length > 0) {
                    title = result.regeocode.pois[0].name;
                } else if (result.regeocode.roads && result.regeocode.roads.length > 0) {
                    title = result.regeocode.roads[0].name;
                } else {
                    title = result.regeocode.addressComponent?.district || address;
                }
            }

            const marker = dataService.createMarker(
                currentTrip.id,
                latitude,
                longitude,
                title,
                address
            );

            renderMap();
            selectMarker(marker);
        });
    } else {
        // Fallback to mock coordinates
        const title = `位置 ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
        const address = `纬度: ${latitude.toFixed(4)}, 经度: ${longitude.toFixed(4)}`;

        const marker = dataService.createMarker(
            currentTrip.id,
            latitude,
            longitude,
            title,
            address
        );

        renderMap();
        selectMarker(marker);
    }
}

// Edit Marker
function editMarker() {
    if (!selectedMarker) return;

    document.getElementById('markerTitleInput').value = selectedMarker.title;
    document.getElementById('markerAddressInput').value = selectedMarker.address;
    document.getElementById('markerNotesInput').value = selectedMarker.notes || '';
    document.getElementById('markerLinkInput').value = selectedMarker.link || '';
    document.getElementById('markerCategoryInput').value = selectedMarker.category || '';

    // Set color selection
    selectedMarkerColor = selectedMarker.color || '#F44336';
    document.querySelectorAll('.color-option').forEach(el => {
        el.classList.toggle('selected', el.dataset.color === selectedMarkerColor);
    });

    // Load existing images
    uploadedImages = [];
    const existingImages = dataService.getImagesByMarkerId(selectedMarker.id);
    existingImages.forEach(img => {
        uploadedImages.push({
            id: img.id,
            dataUrl: img.dataUrl,
            isNew: false
        });
    });

    renderUploadedImages();
    showDialog('marker');
}

// Render Uploaded Images in Dialog
function renderUploadedImages() {
    const container = document.getElementById('uploadedImages');
    if (uploadedImages.length === 0) {
        container.innerHTML = '';
        return;
    }

    container.innerHTML = uploadedImages.map((img, index) => `
        <div class="uploaded-image-item">
            <img src="${img.dataUrl}" alt="上传的图片 ${index + 1}">
            <button class="remove-btn" onclick="removeUploadedImage(${index})" title="删除">×</button>
        </div>
    `).join('');
}

// Handle Image Upload
function handleImageUpload(event) {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    Array.from(files).forEach(file => {
        if (!file.type.startsWith('image/')) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            uploadedImages.push({
                dataUrl: e.target.result,
                isNew: true
            });
            renderUploadedImages();
        };
        reader.readAsDataURL(file);
    });

    // Reset input so same files can be selected again
    event.target.value = '';
}

// Remove Uploaded Image
function removeUploadedImage(index) {
    const img = uploadedImages[index];
    if (img.id && !img.isNew) {
        // Delete existing image from database
        dataService.deleteImage(img.id);
    }
    uploadedImages.splice(index, 1);
    renderUploadedImages();
}

// Save Marker
function saveMarker() {
    if (!selectedMarker) return;

    const title = document.getElementById('markerTitleInput').value.trim();
    if (!title) {
        alert('请输入标题');
        return;
    }

    // Save marker data
    dataService.updateMarker(selectedMarker.id, {
        title: title,
        address: document.getElementById('markerAddressInput').value.trim(),
        notes: document.getElementById('markerNotesInput').value.trim() || null,
        link: document.getElementById('markerLinkInput').value.trim() || null,
        color: selectedMarkerColor,
        category: document.getElementById('markerCategoryInput').value || null
    });

    // Save images
    uploadedImages.forEach((img, index) => {
        if (img.isNew) {
            dataService.addImage(selectedMarker.id, img.dataUrl);
        }
    });

    // Update trip cover if this is the first image
    const allImages = dataService.getImagesByMarkerId(selectedMarker.id);
    if (allImages.length > 0) {
        dataService.updateTripCover(currentTrip.id);
    }

    closeDialog();
    renderMap();
    selectMarker(dataService.getMarkerById(selectedMarker.id));
    renderTripList(); // Update trip list for cover image
}

// Delete Marker
function deleteMarker() {
    if (!selectedMarker) return;

    if (confirm(`确定要删除"${selectedMarker.title}"吗？`)) {
        dataService.deleteMarker(selectedMarker.id);
        closeMarkerInfo();
        renderMap();
        renderTripList(); // Update trip list
    }
}

// Clear Markers
function clearMarkers() {
    if (dataService.getMarkersByTripId(currentTrip.id).length === 0) {
        alert('暂无标记可清空');
        return;
    }

    if (confirm('确定要清空所有标记吗？')) {
        dataService.clearMarkersByTripId(currentTrip.id);
        closeMarkerInfo();
        renderMap();
        renderTripList(); // Update trip list
    }
}

// Show Marker List
function showMarkerList() {
    const markers = dataService.getMarkersByTripId(currentTrip.id);
    document.getElementById('markerListCount').textContent = `${markers.length} 个`;

    const markerListEl = document.getElementById('markerList');
    if (markers.length === 0) {
        markerListEl.innerHTML = '<p style="text-align: center; color: var(--text-secondary);">暂无标记</p>';
    } else {
        markerListEl.innerHTML = markers.map((marker, index) => {
            const images = dataService.getImagesByMarkerId(marker.id);
            const imageCount = images.length > 0 ? `<span>📷 ${images.length}</span>` : '';
            const categoryBadge = marker.category ? `<span class="category-badge" style="background: ${getCategoryColor(marker.category)};">${escapeHtml(marker.category)}</span>` : '';

            return `
                <div class="marker-list-item draggable" data-marker-id="${marker.id}" draggable="true">
                    <div class="drag-handle">⋮⋮</div>
                    <div class="number">${index + 1}</div>
                    ${images.length > 0 ? `<img src="${images[0].dataUrl}" class="list-thumb" style="width: 40px; height: 40px; border-radius: 4px; object-fit: cover;">` : ''}
                    <div class="info">
                        <h4>${escapeHtml(marker.title)}</h4>
                        <p>${escapeHtml(marker.address)}</p>
                        ${categoryBadge}
                    </div>
                    ${imageCount}
                    <button class="icon-btn small" onclick="event.stopPropagation(); selectMarkerById(${marker.id}); closeMarkerList();" title="在地图上查看">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"/>
                            <circle cx="12" cy="12" r="3"/>
                        </svg>
                    </button>
                </div>
            `;
        }).join('');
    }

    // Setup drag and drop
    setupMarkerListDrag();

    markerListSheet.style.display = 'flex';
}

// Setup drag and drop for marker list
function setupMarkerListDrag() {
    const items = document.querySelectorAll('.marker-list-item.draggable');
    let draggedItem = null;

    items.forEach(item => {
        item.addEventListener('dragstart', (e) => {
            draggedItem = item;
            item.style.opacity = '0.5';
            e.dataTransfer.effectAllowed = 'move';
        });

        item.addEventListener('dragend', () => {
            item.style.opacity = '1';
            draggedItem = null;
        });

        item.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
        });

        item.addEventListener('drop', (e) => {
            e.preventDefault();
            if (draggedItem && draggedItem !== item) {
                const markers = dataService.getMarkersByTripId(currentTrip.id);
                const draggedId = parseInt(draggedItem.dataset.markerId);
                const targetId = parseInt(item.dataset.markerId);

                const draggedIndex = markers.findIndex(m => m.id === draggedId);
                const targetIndex = markers.findIndex(m => m.id === targetId);

                // Reorder array
                const [removed] = markers.splice(draggedIndex, 1);
                markers.splice(targetIndex, 0, removed);

                // Update display order
                markers.forEach((m, i) => {
                    dataService.updateMarker(m.id, { displayOrder: i });
                });

                // Refresh list
                showMarkerList();
                renderMap(); // Re-render map to show updated route
            }
        });
    });
}

function selectMarkerById(id) {
    const marker = dataService.getMarkerById(id);
    if (marker) {
        selectMarker(marker);
    }
}

function closeMarkerList() {
    markerListSheet.style.display = 'none';
}

// Image Preview Functions
function openImagePreview(markerId, index) {
    const images = dataService.getImagesByMarkerId(markerId);
    if (images.length === 0) return;

    previewImages = images;
    currentPreviewIndex = index;
    showPreviewImage();
}

function showPreviewImage() {
    previewImage.src = previewImages[currentPreviewIndex].dataUrl;
    document.querySelector('.preview-counter').textContent =
        `${currentPreviewIndex + 1} / ${previewImages.length}`;

    // Update button states
    document.querySelector('.preview-prev').style.visibility =
        currentPreviewIndex === 0 ? 'hidden' : 'visible';
    document.querySelector('.preview-next').style.visibility =
        currentPreviewIndex === previewImages.length - 1 ? 'hidden' : 'visible';

    imagePreviewModal.style.display = 'flex';
}

function prevImage() {
    if (currentPreviewIndex > 0) {
        currentPreviewIndex--;
        showPreviewImage();
    }
}

function nextImage() {
    if (currentPreviewIndex < previewImages.length - 1) {
        currentPreviewIndex++;
        showPreviewImage();
    }
}

function closeImagePreview() {
    imagePreviewModal.style.display = 'none';
    previewImages = [];
    currentPreviewIndex = 0;
}

// Dialog Functions
function showCreateTripDialog() {
    document.getElementById('tripDialogTitle').textContent = '创建新行程';
    document.getElementById('tripNameInput').value = '';
    document.getElementById('tripDialogConfirm').textContent = '创建';
    document.getElementById('tripDialogConfirm').onclick = createTrip;
    showDialog('trip');
    setTimeout(() => document.getElementById('tripNameInput').focus(), 100);
}

function showEditTripDialog(tripId) {
    const trip = dataService.getTripById(tripId);
    if (!trip) return;

    document.getElementById('tripDialogTitle').textContent = '编辑行程';
    document.getElementById('tripNameInput').value = trip.name;
    document.getElementById('tripDialogConfirm').textContent = '保存';
    document.getElementById('tripDialogConfirm').onclick = () => editTrip(tripId);
    showDialog('trip');
    setTimeout(() => document.getElementById('tripNameInput').focus(), 100);
}

function createTrip() {
    const name = document.getElementById('tripNameInput').value.trim();
    if (!name) {
        alert('请输入行程名称');
        return;
    }

    dataService.createTrip(name);
    closeDialog();
    renderTripList();
}

function editTrip(tripId) {
    const name = document.getElementById('tripNameInput').value.trim();
    if (!name) {
        alert('请输入行程名称');
        return;
    }

    dataService.updateTrip(tripId, name);
    closeDialog();
    renderTripList();
}

function deleteTrip(tripId) {
    const trip = dataService.getTripById(tripId);
    if (!trip) return;

    if (confirm(`删除行程"${trip.name}"将同时删除所有相关标记和图片，确定要删除吗？`)) {
        dataService.deleteTrip(tripId);
        renderTripList();
    }
}

function showDialog(type) {
    dialogOverlay.style.display = 'block';
    if (type === 'trip') {
        tripDialog.style.display = 'block';
    } else if (type === 'marker') {
        markerDialog.style.display = 'block';
    }
}

function closeDialog() {
    dialogOverlay.style.display = 'none';
    tripDialog.style.display = 'none';
    markerDialog.style.display = 'none';
    uploadedImages = [];
    // Reset color selection
    selectedMarkerColor = '#F44336';
    document.querySelectorAll('.color-option').forEach(el => {
        el.classList.toggle('selected', el.dataset.color === selectedMarkerColor);
    });
}

// Utility Functions
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Escape string for JavaScript (prevent quote issues)
function escapeJsString(text) {
    return (text || '').replace(/'/g, "\\'").replace(/"/g, '\\"');
}

// Click outside to close bottom sheet
document.addEventListener('click', (e) => {
    if (markerListSheet.style.display === 'flex') {
        if (!markerListSheet.contains(e.target) && !e.target.closest('[onclick*="showMarkerList"]')) {
            closeMarkerList();
        }
    }
});

// ============ Search Functions ============

// Perform AutoComplete search for input suggestions
function performAutoCompleteSearch(keyword) {
    if (!autoComplete) {
        console.warn('AutoComplete not initialized, waiting for AMap...');
        // AMap可能还在加载，等待后重试
        setTimeout(() => {
            if (autoComplete) {
                performAutoCompleteSearch(keyword);
            }
        }, 500);
        return;
    }

    autoComplete.search(keyword, (status, result) => {
        if (status === 'complete' && result && result.tips && result.tips.length > 0) {
            // Filter results that have location data
            const validTips = result.tips.filter(tip => tip.location && tip.location.lng && tip.location.lat);
            displayAutoCompleteResults(validTips);
        } else {
            // No autoComplete results, hide dropdown
            searchResults.style.display = 'none';
        }
    });
}

// Display AutoComplete results
function displayAutoCompleteResults(tips) {
    if (!tips || tips.length === 0) {
        searchResults.style.display = 'none';
        return;
    }

    searchResults.innerHTML = tips.slice(0, 8).map(tip => {
        const name = tip.name || '';
        const address = tip.address || tip.district || '';
        const lng = tip.location.lng;
        const lat = tip.location.lat;

        return `
            <div class="search-result-item" onclick="selectSearchResult(${lat}, ${lng}, '${escapeJsString(name)}', '${escapeJsString(address)}')">
                <div class="search-result-name">${escapeHtml(name)}</div>
                <div class="search-result-address">${escapeHtml(address)}</div>
            </div>
        `;
    }).join('');

    searchResults.style.display = 'block';
}

// Perform place search with POI support (search button)
function performSearch(keyword) {
    console.log('performSearch called with keyword:', keyword);
    console.log('placeSearch initialized:', !!placeSearch);

    if (!placeSearch) {
        console.warn('PlaceSearch not initialized, waiting for AMap...');
        // 显示加载提示
        searchResults.innerHTML = `
            <div class="search-result-item" style="cursor: default;">
                <div class="search-result-name">正在加载搜索服务...</div>
            </div>
        `;
        searchResults.style.display = 'block';

        // 等待后重试
        setTimeout(() => {
            if (placeSearch) {
                performSearch(keyword);
            }
        }, 500);
        return;
    }

    // 使用PlaceSearch进行POI模糊搜索
    placeSearch.search(keyword, (status, result) => {
        console.log('Search result status:', status);
        console.log('Search result:', result);

        if (status === 'complete' && result && result.poiList && result.poiList.pois) {
            displaySearchResults(result.poiList.pois);
        } else if (status === 'no_data') {
            // 如果POI搜索无结果，尝试使用关键字搜索
            placeSearch.search(keyword, (status, result) => {
                if (status === 'complete' && result && result.poiList && result.poiList.pois) {
                    displaySearchResults(result.poiList.pois);
                } else {
                    displayNoResults();
                }
            });
        } else {
            displayNoResults();
        }
    });
}

// Display search results
function displaySearchResults(results) {
    if (!results || results.length === 0) {
        displayNoResults();
        return;
    }

    searchResults.innerHTML = results.slice(0, 10).map(item => {
        const name = item.name || '';
        const address = item.address || item.pname + item.cityname + item.adname || '';
        const location = item.location;

        // Get coordinates from location object
        let lng, lat;
        if (location) {
            lng = location.lng;
            lat = location.lat;
        }

        if (!lng || !lat) return '';

        // Get distance if available
        const distance = item.distance ? `${(item.distance / 1000).toFixed(1)}km` : '';

        // Get type if available
        const type = item.type || '';
        const category = item.shopType || '';

        // Build display info
        let infoHtml = escapeHtml(address);
        if (distance) {
            infoHtml += ` · ${distance}`;
        }

        return `
            <div class="search-result-item" onclick="selectSearchResult(${lat}, ${lng}, '${escapeJsString(name)}', '${escapeJsString(address)}')">
                <div class="search-result-name">${escapeHtml(name)}</div>
                <div class="search-result-address">${infoHtml}</div>
                ${type ? `<div class="search-result-type">${escapeHtml(category || type)}</div>` : ''}
            </div>
        `;
    }).join('');

    searchResults.style.display = 'block';
}

// Display no results message
function displayNoResults() {
    searchResults.innerHTML = `
        <div class="search-result-item" style="cursor: default;">
            <div class="search-result-name">未找到相关地点</div>
            <div class="search-result-address">请尝试其他关键词</div>
        </div>
    `;
    searchResults.style.display = 'block';
}

// Select search result and add marker
function selectSearchResult(lat, lng, name, address) {
    // Hide search results
    searchResults.style.display = 'none';
    searchInput.value = name;
    searchClear.style.display = 'flex';

    // Move map to the location
    if (amap) {
        amap.setCenter([lng, lat]);
        amap.setZoom(15);
    }

    // Add marker at the location
    addMarker(lat, lng, name, address);
}

// Search button click
function searchPlace() {
    const keyword = searchInput.value.trim();
    if (keyword) {
        performSearch(keyword);
    }
}

// Clear search
function clearSearch() {
    searchInput.value = '';
    searchResults.style.display = 'none';
    searchClear.style.display = 'none';
    searchInput.focus();
}

// Initialize app
init();
