var highlightLayer;
function highlightFeature(e) {
    highlightLayer = e.target;

    if (e.target.feature.geometry.type === 'LineString' || e.target.feature.geometry.type === 'MultiLineString') {
        highlightLayer.setStyle({
        color: '#ffff00',
        });
    } else {
        highlightLayer.setStyle({
        fillColor: '#ffff00',
        fillOpacity: 1
        });
    }
}

// Load Leaflet map
var map = L.map('citizenMap', {
    zoomControl: false,
    maxZoom: 20,
    minZoom: 14,
    scrollWheelZoom: true,
    wheelDebounceTime: 150,     // Increased debounce time
    wheelPxPerZoomLevel: 120,   // Increased pixels per zoom level
    zoomSnap: 0.5,
    zoomDelta: 0.5,
    preferCanvas: true,         // Use Canvas renderer for better performance
    updateWhenZooming: false,   // Delay update until zoom ends
    updateWhenIdle: true,       // Only update when map is idle
    markerZoomAnimation: true,
    bounceAtZoomLimits: false,
    maxBoundsViscosity: 1.0
});

// Always fit to Padre Garcia boundary
map.setView([13.8723, 121.2475], 13);

// Force reset view on page load
window.addEventListener('load', function() {
    map.setView([13.8723, 121.2475], 13);
    // Trigger resize to ensure proper centering
    map.invalidateSize();
});

// Debounce function to limit how often a function can be called
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Create a ResizeObserver to handle container size changes
const mapContainer = document.getElementById('citizenMap');
const resizeObserver = new ResizeObserver(debounce(entries => {
    for (let entry of entries) {
        // Get the current center and zoom before resize
        const center = map.getCenter();
        const zoom = map.getZoom();
        
        // Trigger resize
        map.invalidateSize();
        
        // Restore the view
        map.setView(center, zoom);
    }
}, 100)); // Only run every 100ms

// Start observing the map container
resizeObserver.observe(mapContainer);

var userLayer = L.layerGroup().addTo(map); // Layer for user-added markers
var selectedLatLng = null; // Store clicked location
var hash = new L.Hash(map);
var lastClickedBarangay = null; // Store the last barangay clicked

map.attributionControl.setPrefix('<a href="https://github.com/tomchadwin/qgis2web" target="_blank" style="z-index: 998;">qgis2web</a> &middot; <a href="https://leafletjs.com" title="A JS library for interactive maps" style="z-index: 998;">Leaflet</a> &middot; <a href="https://qgis.org" style="z-index: 998;">QGIS</a>');
var autolinker = new Autolinker({truncate: {length: 30, location: 'smart'}});

// remove popup's row if "visible-with-data"
function removeEmptyRowsFromPopupContent(content, feature) {
    var tempDiv = document.createElement('div');
    tempDiv.innerHTML = content;
    var rows = tempDiv.querySelectorAll('tr');
    for (var i = 0; i < rows.length; i++) {
        var td = rows[i].querySelector('td.visible-with-data');
        var key = td ? td.id : '';
        if (td && td.classList.contains('visible-with-data') && feature.properties[key] == null) {
            rows[i].parentNode.removeChild(rows[i]);
        }
    }
    return tempDiv.innerHTML;
}

// add class to format popup if it contains media
function addClassToPopupIfMedia(content, popup) {
    var tempDiv = document.createElement('div');
    tempDiv.innerHTML = content;
    if (tempDiv.querySelector('td img')) {
        popup._contentNode.classList.add('media');
            // Delay to force the redraw
            setTimeout(function() {
                popup.update();
            }, 10);
    } else {
        popup._contentNode.classList.remove('media');
    }
}
var zoomControl = L.control.zoom({
    position: 'topleft'
}).addTo(map);
L.control.locate({locateOptions: {maxZoom: 19}}).addTo(map);
var measureControl = new L.Control.Measure({
    position: 'topleft',
    primaryLengthUnit: 'feet',
    secondaryLengthUnit: 'miles',
    primaryAreaUnit: 'sqfeet',
    secondaryAreaUnit: 'sqmiles'
});
measureControl.addTo(map);
document.getElementsByClassName('leaflet-control-measure-toggle')[0].innerHTML = '';
document.getElementsByClassName('leaflet-control-measure-toggle')[0].className += ' fas fa-ruler';
var bounds_group = new L.featureGroup([]);
function setBounds() {
}
map.createPane('pane_OpenStreetMap_0');
map.getPane('pane_OpenStreetMap_0').style.zIndex = 400;

var layer_OpenStreetMap_0 = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    pane: 'pane_OpenStreetMap_0',
    opacity: 1.0,
    attribution: '',
    minZoom: 14,
    maxZoom: 20,
    maxNativeZoom: 19,              // Limit max native zoom
    updateWhenIdle: true,           // Only update when map is idle
    updateWhenZooming: false,       // Don't update while zooming
    keepBuffer: 2,                  // Increased buffer for smoother panning
    tileSize: 512,                  // Larger tiles = fewer requests
    zoomOffset: -1,                 // Adjust zoom for larger tiles
    crossOrigin: true,              // Enable tile caching
    noWrap: true,                   // Prevent tile wrapping around globe
    subdomains: 'abc',
    noWrap: true,
    detectRetina: true,           // Better display on high DPI screens
    preferCanvas: true,           // Use Canvas renderer for better performance
    updateInterval: 200,          // Reduce update frequency
});
// layer_OpenStreetMap_0;
map.addLayer(layer_OpenStreetMap_0);

function pop_PG_Brgy_Boundary_Cadastral_edited_1(feature, layer) {
    layer.on({
        mouseout: function(e) {
            for (var i in e.target._eventParents) {
                if (typeof e.target._eventParents[i].resetStyle === 'function') {
                    e.target._eventParents[i].resetStyle(e.target);
                }
            }
        },
        mouseover: highlightFeature,
    });
    var popupContent = '<table>\
            <tr>\
                <td colspan="2">' + (feature.properties['Barangay'] !== null ? autolinker.link(String(feature.properties['Barangay']).replace(/'/g, '\'').toLocaleString()) : '') + '</td>\
            </tr>\
            <tr>\
                <td colspan="2">' + (feature.properties['Area_ha'] !== null ? autolinker.link(String(feature.properties['Area_ha']).replace(/'/g, '\'').toLocaleString()) : '') + '</td>\
            </tr>\
        </table>';
    var content = removeEmptyRowsFromPopupContent(popupContent, feature);
    layer.on('popupopen', function(e) {
        addClassToPopupIfMedia(content, e.popup);
    });
    layer.bindPopup(content, { maxHeight: 400 });
}

function style_PG_Brgy_Boundary_Cadastral_edited_1_0() {
    return {
        pane: 'pane_PG_Brgy_Boundary_Cadastral_edited_1',
        opacity: 1,
        color: 'rgba(48,18,59,1.0)',
        dashArray: '',
        lineCap: 'square',
        lineJoin: 'bevel',
        weight: 2.0,
        fillOpacity: 0,
        interactive: true,
    }
}

map.createPane('pane_PG_Brgy_Boundary_Cadastral_edited_1');
map.getPane('pane_PG_Brgy_Boundary_Cadastral_edited_1').style.zIndex = 401;
map.getPane('pane_PG_Brgy_Boundary_Cadastral_edited_1').style['mix-blend-mode'] = 'normal';

// Add this variable at the top of your file with other variables
var activeBarangayLayer = null;

// Add this near the top of your file with other variables
const HIGHLIGHT_STYLE = {
    transform: 'translate3d(0,0,0)',
    fillColor: 'rgba(0, 0, 255, 0.4)',
    fillOpacity: 0.5,
    color: 'blue',
    weight: 2
};

function zoomToBarangay(e, feature) {
    var barangayName = feature.properties.Barangay || "Unknown Barangay";
    var layer = e.target;

    if (lastClickedBarangay === barangayName) {
        console.log("Already zoomed to this barangay, ignoring.");
        return;
    }

    lastClickedBarangay = barangayName;
    var bounds = layer.getBounds();
    
    // First pan to the clicked location
    map.panTo(e.latlng, {
        animate: true,
        duration: 0.6,
        easeLinearity: 0.25
    });

    // Then after pan completes, fly to the bounds
    setTimeout(() => {
        map.flyToBounds(bounds, {
            padding: [50, 50],
            maxZoom: 16,
            animate: true,
            duration: 0.6,       // Keep short so it feels like one flow
            easeLinearity: 0.3
        });
    }, 100); // Match delay to pan duration
}

// Handle Barangay Boundary Clicks
var layer_PG_Brgy_Boundary_Cadastral_edited_1 = new L.geoJson(json_PG_Brgy_Boundary_Cadastral_edited_1, {
    attribution: '',
    interactive: true,
    dataVar: 'json_PG_Brgy_Boundary_Cadastral_edited_1',
    layerName: 'layer_PG_Brgy_Boundary_Cadastral_edited_1',
    pane: 'pane_PG_Brgy_Boundary_Cadastral_edited_1',
    style: style_PG_Brgy_Boundary_Cadastral_edited_1_0,
    renderer: L.svg({ 
        padding: 0.5,
        optimizeSpeed: true,
        vectorEffect: true,
        smoothFactor: 2.0
    }),
    maxZoom: 20,
    smoothFactor: 2.0,  // Reduce number of points rendered
    tolerance: 5,        // Increase tolerance for better performance
    onEachFeature: function (feature, layer) {
        layer.on({
            mouseover: function (e) {
                // e.target.setStyle({ fillColor: 'rgba(0, 0, 255, 0.4)', fillOpacity: 0.5 });
                if (activeBarangayLayer !== layer) {
                    layer.setStyle(HIGHLIGHT_STYLE);
                }
            },
            mouseout: function (e) {
                // layer.setStyle(style_PG_Brgy_Boundary_Cadastral_edited_1_0()); // Reset style on mouseout
                if (activeBarangayLayer !== layer) {
                    layer.setStyle(style_PG_Brgy_Boundary_Cadastral_edited_1_0());
                }
            },
            click: function (e) {

                console.log("Barangay clicked at:", e.latlng);

                // Reset previous active barangay
                if (activeBarangayLayer && activeBarangayLayer !== layer) {
                    activeBarangayLayer.setStyle(style_PG_Brgy_Boundary_Cadastral_edited_1_0());
                }

                // Set new active barangay
                activeBarangayLayer = layer;
                layer.setStyle(HIGHLIGHT_STYLE);


                zoomToBarangay(e, feature);

                var lat = e.latlng.lat;
                var lng = e.latlng.lng;
                var streetViewUrl = `https://www.google.com/maps?q=&layer=c&cbll=${lat},${lng}`;

                L.popup()
                    .setLatLng(e.latlng)
                    .setContent(`
                        <b>Barangay:</b> ${feature.properties.Barangay || "Unknown Barangay"}<br>
                        <a href="${streetViewUrl}" target="_blank">📍 View in Google Street View</a>
                    `)
                    .openOn(map);
            }
        });
    }
});

bounds_group.addLayer(layer_PG_Brgy_Boundary_Cadastral_edited_1);
map.addLayer(layer_PG_Brgy_Boundary_Cadastral_edited_1);
function style_Buildings_2_0() {
    return {
        pane: 'pane_Buildings_2',
        opacity: 1,
        color: 'rgba(35,35,35,1.0)',
        dashArray: '',
        lineCap: 'butt',
        lineJoin: 'miter',
        weight: 1.0, 
        fill: true,
        fillOpacity: 1,
        fillColor: 'rgba(190,178,151,1.0)',
        interactive: true,
        clickable: true,
    }
}
map.createPane('pane_Buildings_2');
map.getPane('pane_Buildings_2').style.zIndex = 403;
map.getPane('pane_Buildings_2').style['mix-blend-mode'] = 'normal';

var layer_Buildings_2 = new L.geoJson(json_Buildings_2, {
    attribution: '',
    interactive: true,
    dataVar: 'json_Buildings_2',
    layerName: 'layer_Buildings_2',
    pane: 'pane_Buildings_2',
    // onEachFeature: pop_Buildings_2,
    style: style_Buildings_2_0,
});
bounds_group.addLayer(layer_Buildings_2);
map.addLayer(layer_Buildings_2);
setBounds();

var i = 0;
layer_PG_Brgy_Boundary_Cadastral_edited_1.eachLayer(function(layer) {
    var context = {
        feature: layer.feature,
        variables: {}
    };
    layer.bindTooltip((layer.feature.properties['Barangay'] !== null?String('<div style="color: #30123b; font-size: 12pt; font-family: \'Open Sans\', sans-serif;">' + layer.feature.properties['Barangay']) + '</div>':''), {permanent: true, offset: [-0, -16], className: 'css_PG_Brgy_Boundary_Cadastral_edited_1'});
    labels.push(layer);
    totalMarkers += 1;
        layer.added = true;
        addLabel(layer, i);
        i++;
});

map.addControl(new L.Control.Search({
    layer: layer_Buildings_2,
    initial: false,
    hideMarkerOnCollapse: true,
    propertyName: 'name',
}));
document.getElementsByClassName('search-button')[0].className +=
    ' fa fa-search';

// Initialize Leaflet.draw
var drawnItems = new L.FeatureGroup();
map.addLayer(drawnItems);

// Initialize feature group for hazards
var fetchedHazards = new L.FeatureGroup().addTo(map);

// Create hazard pane
map.createPane('hazardPane');
map.getPane('hazardPane').style.zIndex = 450;
map.getPane("hazardPane").style.pointerEvents = "all";

// Hazard colors mapping
var hazardColors = {
    "fire": "red",
    "flood": "blue",
    "earthquake": "orange",
    "landslide": "brown"
};

// Function to fetch hazards
function fetchHazards() {
    fetch("php/hazards/fetch_citizen_hazards.php")
        .then((response) => {
            if (!response.ok) throw new Error("Network response was not ok");
            return response.json();
        })
        .then((data) => {
            if (data.hazards && Array.isArray(data.hazards)) {
                // Clear existing hazards and legends
                fetchedHazards.clearLayers();

                // Add new hazards
                data.hazards.forEach((hazard) => {
                    try {
                        let parsedLocation = JSON.parse(hazard.location);
                        let hazardType = hazard.hazard_type.toLowerCase();
                        let color = hazardColors[hazardType] || "blue";

                        // Create hazard layer
                        var hazardLayer = L.geoJSON(parsedLocation, {
                            style: {
                                color: color,
                                fillColor: color,
                                fillOpacity: 0.3,
                                weight: 2,
                            },
                            interactive: true,
                            pane: "hazardPane",
                            // Add events directly in options

                        });

                        hazardLayer.hazardData = hazard;

                        // Add to feature group
                        fetchedHazards.addLayer(hazardLayer);

                        // Update legend
                        updateLegend(hazardType, color);
                    } catch (err) {
                        console.error("Error parsing hazard location:", err);
                    }
                });

                // Update all legends
                updateAllLegends();
            }

            // Poll for new hazards every 2 mins
            setTimeout(fetchHazards, 120000);
        })
        .catch((error) => {
            console.error("Error fetching hazards:", error);
            setTimeout(fetchHazards, 3000);
    });
}

// Legend management
var legendItems = {};

function updateLegend(hazardType, color) {
    var legendList = document.getElementById("legend-list");
    if (!legendItems[hazardType]) {
        var listItem = document.createElement("li");
        listItem.innerHTML = `<span style="background: ${color}; width: 10px; height: 10px; display: inline-block;"></span> ${hazardType.charAt(0).toUpperCase() + hazardType.slice(1)}`;
        legendList.appendChild(listItem);
        legendItems[hazardType] = true;
    }
}

function updateAllLegends() {
    var legendList = document.getElementById("legend-list");
    let currentHazardTypes = new Set();

    fetchedHazards.eachLayer(function(layer) {
        if (layer.hazardData && layer.hazardData.hazard_type) {
            currentHazardTypes.add(layer.hazardData.hazard_type.toLowerCase());
        }
    });

    Object.keys(legendItems).forEach(type => {
        if (!currentHazardTypes.has(type.toLowerCase())) {
            let items = legendList.getElementsByTagName("li");
            Array.from(items).forEach(item => {
                if (item.textContent.toLowerCase().includes(type.toLowerCase())) {
                    legendList.removeChild(item);
                }
            });
            delete legendItems[type];
        }
    });
}

function fetchRecentReports() {
    fetch("php/reportings/citizens_reports/fetch_recent_reports.php")
        .then((res) => {
            if (!res.ok) throw new Error("Failed to fetch reports");
            return res.json();
        })
        .then((data) => {
            const list = document.querySelector(".recent-events-list");
            if (!list || !data.reports) return;

            list.innerHTML = "";

            data.reports.forEach((report) => {
                const baranggay = report.baranggay || "Unknown Barangay";
                const dateTime = new Date(`${report.date}T${report.time}`);
                const timeAgo = timeSince(dateTime);

                const li = document.createElement("li");
                li.className = "text-sm flex items-start space-x-2";

                li.innerHTML = `
                    <span class="inline-block w-3 h-3 mt-1 rounded-full bg-blue-500 flex-shrink-0"></span>
                    <div>
                        <p class="font-medium">Incident Reported</p>
                        <p class="text-gray-600">${baranggay}</p>
                        <span class="text-xs text-gray-400">${timeAgo}</span>
                    </div>
                `;

                list.appendChild(li);
            });
        })
        .catch((err) => {
            console.error("Recent reports fetch error:", err);
        });

    setTimeout(fetchRecentReports, 120000);
}

function timeSince(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    const intervals = [
        { label: 'year', seconds: 31536000 },
        { label: 'month', seconds: 2592000 },
        { label: 'day', seconds: 86400 },
        { label: 'hour', seconds: 3600 },
        { label: 'minute', seconds: 60 },
        { label: 'second', seconds: 1 }
    ];

    for (const interval of intervals) {
        const count = Math.floor(seconds / interval.seconds);
        if (count >= 1) {
            return `${count} ${interval.label}${count > 1 ? 's' : ''} ago`;
        }
    }

    return 'just now';
}


document.addEventListener('DOMContentLoaded', function() {
    // Start fetching hazards after everything is loaded
    fetchHazards();

    // Start fetching recent reports
    fetchRecentReports();
});