import React, { useState, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Popup, Circle, useMap } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import Navbar from '../components/Navbar'
import Sidebar from '../components/Sidebar'
import axios from 'axios'

const warningColorMap = {
  high: '#ef4444',
  medium: '#f59e0b',
  normal: '#f59e0b',
  low: '#22c55e',
}

function getWarningColor(warning) {
  return warningColorMap[(warning || 'normal').toLowerCase()] || '#f59e0b'
}

function makeIcon(color) {
  return L.divIcon({
    className: '',
    html: `<div style="width:18px;height:18px;border-radius:50%;
      background:${color};border:3px solid white;
      box-shadow:0 0 0 2px ${color}"></div>`,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
  })
}

function FlyTo({ coords }) {
  const map = useMap()
  useEffect(() => {
    if (coords) map.flyTo([coords.lat, coords.lng], 14)
  }, [coords])
  return null
}

export default function LiveMap() {
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(false)
  const [status, setStatus] = useState({ msg: 'Enter a location to find nearby potholes', type: '' })
  const [center, setCenter] = useState(null)
  const [reports, setReports] = useState([])
  const [meta, setMeta] = useState(null)

  const accessToken = localStorage.getItem('accessToken')

  async function handleSearch() {
    if (!query.trim()) return
    setLoading(true)
    setReports([])
    setMeta(null)
    setStatus({ msg: 'Geocoding location...', type: '' })

    try {
      //Converting location name → lat/lng
      const geoRes = await fetch(
        `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=1`,
        { headers: { 'Accept-Language': 'en' } }
      )
      const geoData = await geoRes.json()
      if (!geoData.length) throw new Error('Location not found. Try a more specific name.')

      const lat = parseFloat(geoData[0].lat)
      const lng = parseFloat(geoData[0].lon)
      setCenter({ lat, lng })
      setStatus({ msg: 'Fetching nearby potholes...', type: '' })

      //Calling nearby API with lat/lng
      const apiRes = await axios.get(
        `https://pitwatch.onrender.com/api/v1/reports/nearby/?lat=${lat}&lng=${lng}&radius_km=1&limit=10`,
        {
          headers: { Authorization: `Bearer ${accessToken}` },
          withCredentials: true,
        }
      )

      const data = apiRes.data
      const list = data.results || []

      setMeta({
        warning: data.warning,
        cluster_count: data.cluster_count,
        threshold: data.threshold,
      })
      setReports(list)
      setStatus(
        list.length
          ? { msg: `${list.length} pothole(s) found within 1 km`, type: 'success' }
          : { msg: 'No potholes found within 1 km of this location', type: 'error' }
      )
    } catch (e) {
      setStatus({ msg: e.message || 'Something went wrong', type: 'error' })
    } finally {
      setLoading(false)
    }
  }

  const statusColor = {
    success: '#15803d',
    error: '#b91c1c',
    '': '#6b7280',
  }[status.type]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh' }}>
      <Navbar />
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        <Sidebar />
        <div style={{ flex: 1, position: 'relative' }}>

          {/* Search Bar */}
          <div style={{
            position: 'absolute', top: 14, left: '50%', transform: 'translateX(-50%)',
            zIndex: 1000, display: 'flex', width: 'min(500px, calc(100% - 32px))',
            background: 'white', borderRadius: 10, overflow: 'hidden',
            border: '1px solid #e5e7eb', boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
          }}>
            <input
              value={query}
              onChange={e => setQuery(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSearch()}
              placeholder="Search location (e.g. Chandni Chowk, Delhi)"
              style={{ flex: 1, border: 'none', outline: 'none', padding: '10px 14px', fontSize: 13 }}
            />
            <button
              onClick={handleSearch}
              disabled={loading}
              style={{
                padding: '0 18px', border: 'none',
                background: loading ? '#93c5fd' : '#1d4ed8',
                color: 'white', fontSize: 13, fontWeight: 500,
                cursor: loading ? 'not-allowed' : 'pointer',
              }}
            >
              {loading ? 'Searching...' : 'Search'}
            </button>
          </div>

          {meta?.warning?.toLowerCase() === 'high' && (
            <div style={{
              position: 'absolute', top: 62, left: '50%', transform: 'translateX(-50%)',
              zIndex: 1000, background: '#fee2e2', border: '1px solid #fca5a5',
              borderRadius: 8, padding: '6px 16px', fontSize: 12,
              color: '#b91c1c', fontWeight: 500, whiteSpace: 'nowrap',
            }}>
              ⚠ High density area — {meta.cluster_count} potholes detected (threshold: {meta.threshold})
            </div>
          )}

          <div style={{
            position: 'absolute', bottom: 14, left: '50%', transform: 'translateX(-50%)',
            zIndex: 1000, background: 'white', borderRadius: 8, padding: '7px 14px',
            fontSize: 12, border: '1px solid #e5e7eb', color: statusColor,
            whiteSpace: 'nowrap',
          }}>
            {status.msg}
          </div>

          <div style={{
            position: 'absolute', bottom: 14, right: 14, zIndex: 1000,
            background: 'white', borderRadius: 10, padding: '10px 14px',
            border: '1px solid #e5e7eb', fontSize: 12,
          }}>
            <div style={{ fontWeight: 500, marginBottom: 7, color: '#111' }}>Warning</div>
            {[['#ef4444', 'High'], ['#f59e0b', 'Medium / Normal'], ['#22c55e', 'Low']].map(([color, label]) => (
              <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 4, color: '#555' }}>
                <div style={{ width: 10, height: 10, borderRadius: '50%', background: color, flexShrink: 0 }} />
                {label}
              </div>
            ))}
          </div>

          <MapContainer center={[20.5937, 78.9629]} zoom={5} style={{ height: '100%', width: '100%' }}>
            <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
            {center && <FlyTo coords={center} />}
            {center && (
              <Circle
                center={[center.lat, center.lng]}
                radius={1000}
                pathOptions={{ color: '#3b82f6', weight: 1.5, fillOpacity: 0.07 }}
              />
            )}
            {reports.map(r => (
              <Marker
                key={r.id}
                position={[r.latitude, r.longitude]}
                icon={makeIcon(getWarningColor(meta?.warning))}
              >
                <Popup>
                  <div style={{ fontFamily: 'sans-serif', fontSize: 13, minWidth: 190 }}>
                    <div style={{ fontWeight: 600, marginBottom: 5 }}>{r.title || 'Pothole Report'}</div>
                    <div style={{ color: '#555', marginBottom: 2 }}>
                      Status: <b>{r.status}</b>
                    </div>
                    <div style={{ color: '#555', marginBottom: 2 }}>
                      Distance: <b>{r.distance_m} m away</b>
                    </div>
                    <div style={{ color: '#555', marginBottom: 2 }}>
                      Area warning: <b style={{ color: getWarningColor(meta?.warning) }}>{meta?.warning || 'N/A'}</b>
                    </div>
                    <div style={{ color: '#555', marginBottom: 2 }}>
                      Cluster count: <b>{meta?.cluster_count}</b>
                    </div>
                    <div style={{ color: '#9ca3af', fontSize: 11, marginTop: 5 }}>
                      {new Date(r.created_at).toLocaleString()}
                    </div>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>

        </div>
      </div>
    </div>
  )
}