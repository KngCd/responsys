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
var map = L.map('map', {
    zoomControl: false,
    maxZoom: 20,
    minZoom: 13,
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
const mapContainer = document.getElementById('map');
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

map.attributionControl.setPrefix('<a href="https://github.com/tomchadwin/qgis2web" target="_blank">qgis2web</a> &middot; <a href="https://leafletjs.com" title="A JS library for interactive maps">Leaflet</a> &middot; <a href="https://qgis.org">QGIS</a>');
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
    minZoom: 13,
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

                // Stop if the user clicked inside a drawn shape or hazard
                if (isClickInsideDrawnShape(e.latlng) || isClickInsideFetchedHazard(e.latlng)) {
                    console.log("Click ignored: Inside drawn shape or hazard.");
                    return;
                }

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

// Initialize Leaflet.draw with proper edit configuration
var drawControl = new L.Control.Draw({
    draw: {
        polygon: true,
        rectangle: true,
        marker: false,
        polyline: false,
        circle: false,
        circlemarker: false
    },
    edit: {
        featureGroup: drawnItems,
        edit: true,
        remove: false,
        poly: {
            allowIntersection: false
        }
    }
});
map.addControl(drawControl);

// Fix Fetched Hazards Clicks
var fetchedHazards = new L.FeatureGroup(); // Store fetched hazards

// Ensure clicks inside drawn shapes do not trigger barangay click, but show hazard popup    
function isClickInsideDrawnShape(latlng) {
    let clickedPoint = turf.point([latlng.lng, latlng.lat]); // Convert click to GeoJSON point

    let inside = false; // Default to false

    drawnItems.eachLayer(function (layer) {
        if (layer.hazardData && layer.hazardData.geometry) {
            let hazardGeoJSON = layer.hazardData.geometry; // Use exact GeoJSON from DB
            
            // Convert GeoJSON to Turf polygon
            let polygon = turf.polygon(hazardGeoJSON.coordinates);

            if (turf.booleanPointInPolygon(clickedPoint, polygon)) {
                inside = true;

                console.log("Clicked inside a stored hazard. Showing popup.");
                L.popup()
                    .setLatLng(latlng)
                    .setContent(`
                        <div class="p-1">
                            <p class="text-gray-800"><span class="font-semibold">Type:</span> ${layer.hazardData.type}</p>
                            <p class="text-gray-800"><span class="font-semibold">Status:</span> ${layer.hazardData.status}</p>
                            <p class="text-gray-800"><span class="font-semibold">Description:</span> ${layer.hazardData.description}</p>
                            <!-- <button onclick="confirmDeleteHazard(${layer.hazardData.id})"
                                class="mt-2 bg-red-500 text-white px-3 py-1 text-sm rounded hover:bg-red-600 transition">
                                Delete
                            </button> -->
                        </div>
                    `)
                    .openOn(map);
                // drawnItems.addLayer(layer);
            }
        }
    });

    return inside;
}

function isClickInsideFetchedHazard(latlng) {
    let clickedPoint = turf.point([latlng.lng, latlng.lat]); // Convert click to GeoJSON point

    let inside = false; // Default to false

    fetchedHazards.eachLayer(function (layer) {
        if (layer.hazardData && layer.hazardData.geometry) {
            let hazardGeoJSON = layer.hazardData.geometry; // Use exact GeoJSON from DB
            
            // Convert GeoJSON to Turf polygon
            let polygon = turf.polygon(hazardGeoJSON.coordinates);

            if (turf.booleanPointInPolygon(clickedPoint, polygon)) {
                inside = true;

                console.log("Clicked inside a stored hazard. Showing popup.");
                L.popup()
                    .setLatLng(latlng)
                    .setContent(`
                        <div class="p-1">
                            <p class="text-gray-800"><span class="font-semibold">Type:</span> ${layer.hazardData.type}</p>
                            <p class="text-gray-800"><span class="font-semibold">Status:</span> ${layer.hazardData.status}</p>
                            <p class="text-gray-800"><span class="font-semibold">Description:</span> ${layer.hazardData.description}</p>
                            <!-- <button onclick="confirmDeleteHazard(${layer.hazardData.id})"
                                class="mt-2 bg-red-500 text-white px-3 py-1 text-sm rounded hover:bg-red-600 transition">
                                Delete
                            </button> -->
                        </div>
                    `)
                    .openOn(map);
                // drawnItems.addLayer(layer);
            }
        }
    });

    return inside;
}

// Ensure Drawn Shapes are Clickable
map.on(L.Draw.Event.CREATED, function (event) {
    var layer = event.layer;
    var drawnShape = layer.toGeoJSON();
    let allPointsValid = true; // Start true, will become false if any point is outside

    // Check if the drawn shape is completely within any Padre Garcia polygon
    if (drawnShape.geometry.type === 'Polygon') {
        drawnShape.geometry.coordinates[0].forEach(coord => {
            let point = turf.point(coord);
            let pointIsInside = false;
            
            // Check if point is inside ANY boundary
            layer_PG_Brgy_Boundary_Cadastral_edited_1.eachLayer(function(boundaryLayer) {
                if (boundaryLayer.feature && boundaryLayer.feature.geometry) {
                    if (turf.booleanPointInPolygon(point, boundaryLayer.feature)) {
                        pointIsInside = true;
                    }
                }
            });

            // If point isn't inside any boundary, shape is invalid
            if (!pointIsInside) {
                allPointsValid = false;
            }
        });
    }

    if (!allPointsValid) {
        Swal.fire({
            title: "Error",
            text: "Please draw the shape completely inside the Padre Garcia boundary.",
            icon: "error",
            confirmButtonColor: "#d32f2f",
            timer: 1000
        });
        return;
    }


    layer.on('click', function (e) {
        console.log("Clicked on drawn shape", e.latlng);
        L.popup()
            .setLatLng(e.latlng)
            .setContent(`
                <div class="p-1">
                    <p class="text-gray-800"><span class="font-semibold">Type:</span> ${layer.hazardData.type}</p>
                    <p class="text-gray-800"><span class="font-semibold">Status:</span> ${layer.hazardData.status}</p>
                    <p class="text-gray-800"><span class="font-semibold">Description:</span> ${layer.hazardData.description}</p>
                    <!-- <button onclick="confirmDeleteHazard(${layer.hazardData.id})"
                        class="mt-2 bg-red-500 text-white px-3 py-1 text-sm rounded hover:bg-red-600 transition">
                        Delete
                    </button> -->
                </div>
            `)
            .openOn(map);
    });

    drawnItems.addLayer(layer);
    currentGeoJSON = JSON.stringify(layer.toGeoJSON().geometry);
    document.getElementById("form-container").style.display = "block";
});

let activeHazards = new Map();

// Add this function to check and update all legends
function updateAllLegends() {
    var legendList = document.getElementById("legend-list");
    let currentHazardTypes = new Set();

    // Get all current hazard types on the map
    fetchedHazards.eachLayer(function(layer) {
        if (layer.hazardData && layer.hazardData.type) {
            currentHazardTypes.add(layer.hazardData.type.toLowerCase());
        }
    });

    // Remove legends for hazard types that no longer exist
    Object.keys(legendItems).forEach(type => {
        if (!currentHazardTypes.has(type.toLowerCase())) {
            // Remove from legend list
            let items = legendList.getElementsByTagName("li");
            Array.from(items).forEach(item => {
                if (item.textContent.toLowerCase().includes(type.toLowerCase())) {
                    legendList.removeChild(item);
                }
            });
            // Remove from tracking object
            delete legendItems[type];
        }
    });
}

// Function to fetch hazards stored from the database
let lastHazardDataHash = null;

function fetchHazards() {
    fetch("../php/hazards/fetch_hazards.php")
    .then((response) => {
        if (!response.ok) throw new Error("Network response was not ok");
        return response.json();
    })
    .then((data) => {
        if (data.hazards && Array.isArray(data.hazards)) {
        const newHash = JSON.stringify(data.hazards);

        // Only process if changed
        if (newHash !== lastHazardDataHash) {
            lastHazardDataHash = newHash;

            const hazardIds = new Set(data.hazards.map((h) => h.hazard_id));

            // Remove stale hazard layers
            fetchedHazards.eachLayer(function (layer) {
            if (!hazardIds.has(layer.hazardId)) {
                fetchedHazards.removeLayer(layer);
                drawnItems.removeLayer(layer);
                map.removeLayer(layer);
            }
            });

            // Add new or update existing hazards
            data.hazards.forEach((hazard) => {
            try {
                let parsedLocation = JSON.parse(hazard.location);
                let hazardType = hazard.hazard_type.toLowerCase();
                let color = hazardColors[hazardType] || "blue";

                let existingLayer = false;
                let needsUpdate = false;

                fetchedHazards.eachLayer(function (layer) {
                if (layer.hazardId === hazard.hazard_id) {
                    existingLayer = true;
                    if (
                    JSON.stringify(layer.hazardData.geometry) !==
                    JSON.stringify(parsedLocation)
                    ) {
                    needsUpdate = true;
                    fetchedHazards.removeLayer(layer);
                    drawnItems.removeLayer(layer);
                    map.removeLayer(layer);
                    }
                }
                });

                map.createPane("hazardPane");
                map.getPane("hazardPane").style.zIndex = 403;
                map.getPane("hazardPane").style["mix-blend-mode"] = "normal";

                if (!existingLayer || needsUpdate) {
                updateLegend(hazardType, color);

                var hazardLayer = L.geoJSON(parsedLocation, {
                    style: {
                    color: color,
                    fillColor: color,
                    fillOpacity: 0.3,
                    weight: 2,
                    },
                    interactive: true,
                    pane: "hazardPane",
                });

                hazardLayer.eachLayer(function (layer) {
                    layer.hazardId = hazard.hazard_id;
                    layer.hazardData = {
                    id: hazard.hazard_id,
                    type: hazard.hazard_type,
                    status: hazard.status,
                    description: hazard.description,
                    geometry: parsedLocation,
                    };

                    layer.on("click", function (e) {
                    L.DomEvent.stopPropagation(e);
                    L.DomEvent.preventDefault(e);

                    L.popup()
                        .setLatLng(e.latlng)
                        .setContent(
                        `<b>Type:</b> ${hazard.hazard_type} <br>
                        <b>Status:</b> ${hazard.status} <br>
                        <b>Description:</b> ${hazard.description}`
                        )
                        .openOn(map);
                    });

                    fetchedHazards.addLayer(layer);
                    drawnItems.addLayer(layer);
                });

                map.addLayer(hazardLayer);
                }
            } catch (err) {
                console.error("Error parsing hazard location:", err);
                Swal.fire({
                title: "Error",
                text: "Error parsing hazard location.",
                icon: "error",
                confirmButtonColor: "#d32f2f",
                timer: 1000,
                });
            }
            });

            updateAllLegends();
        }
        }

        // Schedule next poll
        setTimeout(fetchHazards, 1000);

    })
    .catch((error) => {
        console.error("Fetch error in hazards:", error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error fetching hazards.',
            confirmButtonColor: "#d32f2f",
            timer: 1000
        });
        setTimeout(fetchHazards, 3000);
    });
}

// Start it
fetchHazards();

var hazardColors = {
    "fire": "red",
    "flood": "blue",
    "earthquake": "orange",
    "landslide": "brown"
};

var legendItems = {}; // Store legend items to avoid duplicates

// Function to update the legend on the map
function updateLegend(hazardType, color) {
    var legendList = document.getElementById("legend-list");

    // Check if legend item already exists
    if (!legendItems[hazardType]) {
        var listItem = document.createElement("li");
        listItem.innerHTML = `<span style="background: ${color}; width: 10px; height: 10px; display: inline-block;"></span> ${hazardType.charAt(0).toUpperCase() + hazardType.slice(1)}`;
        legendList.appendChild(listItem);

        // Mark hazard type as added to prevent duplicates
        legendItems[hazardType] = true;
    }
}

// Function to update the hazard's coordinate
function updateHazardOnMap(hazardId, newGeoJSON, hazardType, hazardStatus, hazardDescription) {
    // let hazardType = null; // Store hazard type
    let color = "blue"; // Default color

    // Find the existing layer to retrieve hazard type
    fetchedHazards.eachLayer(function (layer) {
        if (layer.hazardId == hazardId) {
            hazardType = layer.hazardData.type.toLowerCase(); // Get stored type
            color = hazardColors[hazardType] || "blue"; // Use predefined color
            map.removeLayer(layer); // Remove old layer
        }
    });

    // Create updated layer with correct color
    let updatedLayer = L.geoJSON(newGeoJSON, {
        style: {
            color: color,
            fillColor: color,
            fillOpacity: 0.3,
            weight: 2
        },
        interactive: true
    });

    updatedLayer.eachLayer(function (newLayer) {
        newLayer.hazardId = hazardId;
        newLayer.hazardData = { 
            id: hazardId, 
            type: hazardType, 
            status: hazardStatus, 
            description: hazardDescription, 
            geometry: newGeoJSON 
        };

        // Reattach click event
        newLayer.on('click', function(e) {
            console.log("Updated hazard clicked at:", e.latlng);

            L.popup()
                .setLatLng(e.latlng)
                .setContent(`
                    <div class="p-1">
                        <p class="text-gray-800"><span class="font-semibold">Type:</span> ${newLayer.hazardData.type}</p>
                        <p class="text-gray-800"><span class="font-semibold">Status:</span> ${newLayer.hazardData.status}</p>
                        <p class="text-gray-800"><span class="font-semibold">Description:</span> ${newLayer.hazardData.description}</p>
                        <button onclick="confirmDeleteHazard(${newLayer.hazardData.id})"
                            class="mt-2 bg-red-500 text-white px-3 py-1 text-sm rounded hover:bg-red-600 transition">
                            Delete
                        </button>
                    </div>
                `)
                .openOn(map);
        });

        fetchedHazards.addLayer(newLayer);
        drawnItems.addLayer(newLayer);
    });

    map.addLayer(updatedLayer); // Add updated layer back to map
}
        
map.on('draw:edited', function (event) {
    event.layers.eachLayer(function (layer) {
        if (layer.hazardId) {
            let updatedGeoJSON = layer.toGeoJSON().geometry;
            let allPointsValid = true; // Start true, will become false if any point is outside

            // Check each point of the polygon
            if (updatedGeoJSON.type === 'Polygon') {
                // Check every point against all boundaries
                updatedGeoJSON.coordinates[0].forEach(coord => {
                    let point = turf.point(coord);
                    let pointIsInside = false;
                    
                    // Check if point is inside ANY boundary
                    layer_PG_Brgy_Boundary_Cadastral_edited_1.eachLayer(function(boundaryLayer) {
                        if (boundaryLayer.feature && boundaryLayer.feature.geometry) {
                            if (turf.booleanPointInPolygon(point, boundaryLayer.feature)) {
                                pointIsInside = true;
                            }
                        }
                    });

                    // If point isn't inside any boundary, shape is invalid
                    if (!pointIsInside) {
                        allPointsValid = false;
                    }
                });
            }
            if (!allPointsValid) {
                Swal.fire({
                  title: "Error",
                  text: "Please keep the shape completely inside the Padre Garcia boundary.",
                  icon: "error",
                  confirmButtonColor: "#d32f2f",
                  timer: 1000
                });

                // Revert this specific layer to its original state
                layer.setLatLngs(layer.getLatLngs());
                layer.editing.disable();
                layer.editing.enable();
                
                // Force refresh the layer
                if (layer.hazardData && layer.hazardData.geometry) {
                    updateHazardOnMap(
                        layer.hazardId,
                        layer.hazardData.geometry,
                        layer.hazardData.type,
                        layer.hazardData.status,
                        layer.hazardData.description
                    );
                }
                return;
            }

            // Continue with update if shape is valid
            let updatedData = {
                hazard_id: layer.hazardId,
                location: JSON.stringify(updatedGeoJSON)
            };

            // Rest of your existing update code...
            fetch("../php/hazards/update_hazard.php", {
                method: "POST",
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
                body: `hazard_id=${updatedData.hazard_id}&location=${encodeURIComponent(updatedData.location)}`
            })
            .then(response => response.json())
            .then(data => {
                console.log(`Server Response:`, data);
                Swal.fire({
                    title: "Success!",
                    text: "Hazard updated successfully!",
                    icon: "success",
                    confirmButtonColor: "#52b855",
                    timer: 1000
                });

                // updateHazardOnMap(
                //     layer.hazardId,
                //     updatedGeoJSON,
                //     layer.hazardData.type,
                //     layer.hazardData.status,
                //     layer.hazardData.description
                // );
            })
            .catch(error => {
                console.error("Error updating hazard:", error);
                Swal.fire({
                    title: "Error",
                    text: "Error updating hazard.",
                    icon: "error",
                    confirmButtonColor: "#d32f2f",
                    timer: 1000
                });
            });
        }
    });
});

// Function to cancel the form
function cancelForm() {
    document.getElementById("form-container").style.display = "none";
    document.getElementById("locationForm").reset();

    // Get all layers in drawnItems
    const layers = drawnItems.getLayers();
    
    // If there are layers, remove only the last one
    if (layers.length > 0) {
        const lastLayer = layers[layers.length - 1];
        drawnItems.removeLayer(lastLayer);
    }
    
    // Reset the current GeoJSON
    currentGeoJSON = null;
}

// Form submission to save the shape
document.getElementById("locationForm").addEventListener("submit", function (e) {
    e.preventDefault();
    if (!currentGeoJSON) return;

    var hazardType = document.getElementById("hazard_type").value;
    var status = document.getElementById("status").value;
    var description = document.getElementById("description").value;

    fetch("../php/hazards/save_hazard.php", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: `hazard_type=${encodeURIComponent(hazardType)}&status=${encodeURIComponent(status)}&description=${encodeURIComponent(description)}&location=${encodeURIComponent(currentGeoJSON)}`
    }).then(response => response.text())
    .then(data => {
        Swal.fire({
            title: 'Success!',
            text: 'Hazard saved successfully!',
            icon: 'success',
            confirmButtonColor: '#52b855',
            timer: 1000
        });
        
        // Reset the entire form
        document.getElementById("locationForm").reset();
        // Clear the temporary drawn shape
        // drawnItems.clearLayers();

        // Only remove the temporary drawn shape, not all layers
        const layers = drawnItems.getLayers();
        const lastLayer = layers[layers.length - 1];
        if (lastLayer && !lastLayer.hazardId) {
            drawnItems.removeLayer(lastLayer);
        }

        // location.reload(); // Reload the page to refresh hazards
        // fetchHazards();
    })
    .catch(error => {
        console.error("Error:", error);
        Swal.fire({
            title: "Error",
            text: "Fetch error.",
            icon: "error",
            confirmButtonColor: "#d32f2f",
            timer: 1000
        });
    });

    document.getElementById("form-container").style.display = "none";
});

// Function to highlight a specific hazard
function highlightSpecificHazard(hazardId) {
    map.whenReady(() => {
        let foundLayer = null;

        // First check if hazard exists and is active
        fetchedHazards.eachLayer(layer => {
            if (layer.hazardId == hazardId && 
                layer.hazardData && 
                layer.hazardData.status.toLowerCase() === 'active') {
                foundLayer = layer;
            }
        });

        if (!foundLayer) {
            drawnItems.eachLayer(layer => {
                if (layer.hazardId == hazardId && 
                    layer.hazardData && 
                    layer.hazardData.status.toLowerCase() === 'active') {
                    foundLayer = layer;
                }
            });
        }

        if (foundLayer) {
            // For active and existing hazards, remove temp layer after animation
            zoomAndHighlight(foundLayer);
            const popup = L.popup()
                .setLatLng(foundLayer.getBounds().getCenter())
                .setContent(`
                    <div class="p-1">
                        <p class="text-gray-800"><span class="font-semibold">Type:</span> ${foundLayer.hazardData.type}</p>
                        <p class="text-gray-800"><span class="font-semibold">Status:</span> ${foundLayer.hazardData.status}</p>
                        <p class="text-gray-800"><span class="font-semibold">Description:</span> ${foundLayer.hazardData.description}</p>
                    </div>
                `)
                .addTo(map);
        } else {
            // Fetch hazard from server since not active
            fetch(`../php/hazards/get_hazard.php?id=${hazardId}`)
                .then(res => {
                    if (!res.ok) throw new Error('Failed to fetch hazard');
                    return res.json();
                })
                .then(hazard => {
                    if (!hazard || !hazard.location) {
                        console.warn('No hazard data found for ID', hazardId);
                        return;
                    }

                    // Parse GeoJSON location
                    const geojson = JSON.parse(hazard.location);
                    const hazardType = hazard.hazard_type.toLowerCase();
                    const color = hazardColors[hazardType] || "blue";

                    // Create a temporary GeoJSON layer with correct color
                    const tempLayer = L.geoJSON(geojson, {
                        style: {
                            color: color,
                            fillColor: color,
                            fillOpacity: 0.3,
                            weight: 2
                        }
                    }).addTo(map);

                    // Mark this as a temporary layer
                    tempLayer.temp = true;
                    tempLayer.hazardId = hazard.hazard_id;

                    // Attach correct hazard data to layer for popup content
                    tempLayer.hazardData = {
                        id: hazard.hazard_id,
                        type: hazard.hazard_type,
                        status: hazard.status,
                        description: hazard.description,
                        geometry: geojson
                    };

                    // Zoom and highlight temp layer
                    zoomAndHighlight(tempLayer);

                    // For active hazards, remove after animation
                    if (hazard.status.toLowerCase() === 'active') {
                        setTimeout(() => {
                            if (tempLayer && tempLayer.temp) {
                                map.removeLayer(tempLayer);
                            }
                        }, 2500); // Match animation duration
                    }

                    // Show popup
                    const popup = L.popup()
                        .setLatLng(tempLayer.getBounds().getCenter())
                        .setContent(`
                            <div class="p-1">
                                <p class="text-gray-800"><span class="font-semibold">Type:</span> ${tempLayer.hazardData.type}</p>
                                <p class="text-gray-800"><span class="font-semibold">Status:</span> ${tempLayer.hazardData.status}</p>
                                <p class="text-gray-800"><span class="font-semibold">Description:</span> ${tempLayer.hazardData.description}</p>
                            </div>
                        `)
                        .addTo(map);
                })
                .catch(console.error);
        }
    });

    // Helper function to zoom, open popup, pulse animation
    function zoomAndHighlight(layer) {
        let center;
        const originalStyle = {
            fillOpacity: layer.options.style?.fillOpacity || 0.3
        };
    
        // First ensure map is loaded
        if (!map.hasLayer(layer)) {
            layer.addTo(map);
        }
    
        // Wait a small amount of time for layer to be properly added
        setTimeout(() => {
            if (layer.getBounds) {
                const bounds = layer.getBounds();
                center = bounds.getCenter();
                
                // Force map to fly to bounds
                map.flyToBounds(bounds, {
                    padding: [50, 50],
                    maxZoom: 18,
                    duration: 1 // Increased duration slightly
                });
    
                // After zoom completes
                map.once('moveend', () => {
                    // Show popup
                    const popup = L.popup({
                        closeButton: true,
                        autoClose: false,
                        closeOnClick: true
                    })
                    .setLatLng(center)
                    .setContent(`
                        <div class="p-1">
                            <p class="text-gray-800"><span class="font-semibold">Type:</span> ${layer.hazardData.type}</p>
                            <p class="text-gray-800"><span class="font-semibold">Status:</span> ${layer.hazardData.status}</p>
                            <p class="text-gray-800"><span class="font-semibold">Description:</span> ${layer.hazardData.description}</p>
                        </div>`)
                    .openOn(map);
    
                    // Start pulse animation
                    const pulseAnimation = setInterval(() => {
                        layer.setStyle({ fillOpacity: 0.8 });
                        setTimeout(() => {
                            layer.setStyle({ fillOpacity: originalStyle.fillOpacity });
                        }, 250);
                    }, 500);
    
                    // Stop animation after 2 seconds
                    setTimeout(() => {
                        clearInterval(pulseAnimation);
                        layer.setStyle({ fillOpacity: originalStyle.fillOpacity });
                    }, 2000);
                });
            }
        }, 100); // Small delay to ensure layer is added
    }
}

// loading....
document.addEventListener('DOMContentLoaded', function() {
    var loadingCheck = setInterval(function() {
        // Check if the document is still loading
        if (document.readyState === 'complete') {
            document.getElementById('loader-container').classList.add('loader-hidden');
            clearInterval(loadingCheck);
        }
    }, 100);

    // Fallback - hide loader after 5 seconds maximum
    setTimeout(function() {
        document.getElementById('loader-container').classList.add('loader-hidden');
        clearInterval(loadingCheck);
    }, 5000);

    // Check if there's a highlight parameter in the URL
    const urlParams = new URLSearchParams(window.location.search);
    const highlightId = urlParams.get('highlight');
    
    if (highlightId) {
        highlightSpecificHazard(highlightId);
        
        // Remove the 'highlight' parameter from the URL
        const newUrl = window.location.pathname + window.location.search.replace(/[\?&]highlight=[^&]+/, '');
        window.history.replaceState(null, '', newUrl);
    }
});