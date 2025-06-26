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

const PADRE_GARCIA_BOUNDS = [
    [13.88005510304514,121.2057414823282], // Southwest corner
    [13.885586665519138,121.21539261014819]  // Northeast corner
];

// Optimize map initialization
var map = L.map('resident-map', {
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
const mapContainer = document.getElementById('resident-map');
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
// L.control.locate({locateOptions: {maxZoom: 19}}).addTo(map);
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

// Optimize tile layer
var layer_OpenStreetMap_0 = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    pane: 'pane_OpenStreetMap_0',
    opacity: 1.0,
    attribution: '',
    minZoom: 13,
    maxZoom: 20,
    maxNativeZoom: 19,
    updateWhenIdle: true,
    updateWhenZooming: false,
    keepBuffer: 2,             // Increased buffer for smoother panning
    tileSize: 512,            // Larger tiles = fewer requests
    zoomOffset: -1,           // Adjust zoom for larger tiles
    crossOrigin: true,        // Enable tile caching
    noWrap: true,             // Prevent tile wrapping around globe
    subdomains: 'abc',
    noWrap: true
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
map.getPane('pane_PG_Brgy_Boundary_Cadastral_edited_1').style.willChange = 'transform';

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
                if (activeBarangayLayer !== layer) {
                    layer.setStyle(HIGHLIGHT_STYLE);
                }
            },
            mouseout: function (e) {
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

// Update the locate control to show form when location is inside boundary
const locateControl = L.control.locate({
    locateOptions: {
        enableHighAccuracy: true,
        maximumAge: 0,        // Don't use cached position
        timeout: 10000,       // Wait up to 10 seconds
        maxZoom: 18,
        watch: true,         // Watch for location changes
        setView: false       // Don't automatically set the map view
    },
    keepCurrentZoomLevel: true,
    showPopup: false,
    strings: {
        title: "Show my location"
    },
    onLocationFound: function(e) {
        const accuracy = e.accuracy;
        const latlng = e.latlng;

        // Only process if accuracy is good enough (less than 50 meters)
        if (accuracy > 50) {
            Swal.fire({
                title: "Warning",
                text: "Location accuracy is poor. Please try again or select location manually.",
                icon: "warning",
                confirmButtonColor: "#d32f2f",
                timer: 2000
            });
            return;
        }

        let isInside = false;
        let foundBarangay = null;

        layer_PG_Brgy_Boundary_Cadastral_edited_1.eachLayer(function(layer) {
            if (layer.feature && layer.feature.geometry) {
                var point = turf.point([latlng.lng, latlng.lat]);
                var polygon = layer.feature;
                if (turf.booleanPointInPolygon(point, polygon)) {
                    isInside = true;
                    foundBarangay = layer.feature.properties.Barangay || "Unknown Barangay";
                }
            }
        });

        if (isInside) {
             const isEditing = document.getElementById('locationForm').dataset.editingReportId;
             // Check if the form is in editing mode AND the found barangay is different from the original
             const barangayChangedWhileEditing = isEditing && originalBarangayName !== null && foundBarangay !== originalBarangayName;


            selectedLatLng = latlng; // Update selectedLatLng
            selectedBarangay = foundBarangay; // Update selectedBarangay


            // If barangay changed while editing, clear the photo preview and data
            if (barangayChangedWhileEditing) {
                 capturedPhoto.classList.add('hidden');
                 capturedPhoto.src = ''; // Clear the source
                 document.getElementById('photoData').photoFile = null; // Clear any pending new photo data
                 openCameraBtn.textContent = 'Take Photo'; // Reset button text
                 // Removed the Swal.fire here
                 console.log(`Barangay changed to ${foundBarangay} while editing (via locate). Photo cleared, new photo required.`);
            } else if (isEditing && originalBarangayName !== null && foundBarangay === originalBarangayName) {
                 // If in editing mode and located within the original barangay, don't clear photo
                 console.log("Located within original barangay while editing, updating location fields.");
            }

            // Show form and update fields with the new location and barangay
            // Always update the form fields
            formContainer.classList.remove('hidden');
            document.getElementById('location').value =
                `Lat: ${latlng.lat.toFixed(6)}, Lng: ${latlng.lng.toFixed(6)}`;
            document.getElementById('barangay').value = foundBarangay; // Make sure this is updated


            // Center map on location with accuracy circle
            map.setView(latlng, 18);

            // Show accuracy circle
            if (window.accuracyCircle) {
                map.removeLayer(window.accuracyCircle);
            }
            window.accuracyCircle = L.circle(latlng, {
                radius: accuracy / 2,
                color: '#136AEC',
                fillColor: '#136AEC',
                fillOpacity: 0.15,
                weight: 2
            }).addTo(map);
        } else {
            // ... existing error for location outside boundary ...
             const isEditing = document.getElementById('locationForm').dataset.editingReportId;
            formContainer.classList.add('hidden');
            // Only show error Swal if not editing.
            if(!isEditing){
                 Swal.fire({
                     title: "Error",
                     text: "Your location is outside Padre Garcia boundary.",
                     icon: "error",
                     confirmButtonColor: "#d32f2f",
                     timer: 1000
                 });
            }
             // If locate fails or is outside while editing, reset selected location/barangay and form fields
             selectedLatLng = null;
             selectedBarangay = null;
             document.getElementById('location').value = '';
             document.getElementById('barangay').value = '';
        }
    },
    onLocationError: function(err) {
        Swal.fire({
            title: "Error",
            text: "Could not find your location: " + err.message,
            icon: "error",
            confirmButtonColor: "#d32f2f",
            timer: 1000
        });
    }
}).addTo(map);

// loading....
document.addEventListener('DOMContentLoaded', function() {
    var loadingCheck = setInterval(function() {
        if (document.readyState === 'complete') {
            document.getElementById('loader_container').classList.add('loader_hidden');
            clearInterval(loadingCheck);
        }
    }, 100);

    setTimeout(function() {
        document.getElementById('loader_container').classList.add('loader_hidden');
        clearInterval(loadingCheck);
    }, 5000);
});