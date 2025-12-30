'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'

interface Song {
    id: number
    title: string
    lyrics: string
    category?: string
    reference?: string
}

export default function PWAPage() {
    const [songs, setSongs] = useState<Song[]>([])
    const [filteredSongs, setFilteredSongs] = useState<Song[]>([])
    const [searchQuery, setSearchQuery] = useState('')
    const [selectedSong, setSelectedSong] = useState<Song | null>(null)
    const [theme, setTheme] = useState('day')

    useEffect(() => {
        // Load songs from JSON
        if (typeof window !== 'undefined') {
            fetch('/pwa/songs.json')
                .then(res => res.json())
                .then((data: Song[]) => {
                    const sorted = data.sort((a, b) => a.id - b.id)
                    setSongs(sorted)
                    setFilteredSongs(sorted)
                })
                .catch(err => console.error('Error loading songs:', err))

            // Load theme
            const savedTheme = localStorage.getItem('theme') || 'day'
            setTheme(savedTheme)
            document.documentElement.setAttribute('data-theme', savedTheme)
        }
    }, [])

    useEffect(() => {
        if (!searchQuery.trim()) {
            setFilteredSongs(songs)
            return
        }

        const query = searchQuery.toLowerCase()
        const filtered = songs.filter(song =>
            song.title.toLowerCase().includes(query) ||
            song.lyrics.toLowerCase().includes(query) ||
            song.id.toString().includes(query)
        )
        setFilteredSongs(filtered)
    }, [searchQuery, songs])

    const toggleTheme = () => {
        const newTheme = theme === 'day' ? 'night' : 'day'
        setTheme(newTheme)
        localStorage.setItem('theme', newTheme)
        document.documentElement.setAttribute('data-theme', newTheme)
    }

    const showSong = (song: Song) => {
        setSelectedSong(song)
        window.history.pushState({ songId: song.id }, '', `#song${song.id}`)
    }

    const hideSong = () => {
        setSelectedSong(null)
        if (window.location.hash) {
            window.history.back()
        }
    }

    useEffect(() => {
        const handlePopState = () => {
            if (!window.location.hash) {
                setSelectedSong(null)
            }
        }
        window.addEventListener('popstate', handlePopState)
        return () => window.removeEventListener('popstate', handlePopState)
    }, [])

    return (
        <>
            <style jsx global>{`
        @import url('/shared/theme.css');
        @import url('/pwa/style.css');
      `}</style>

            <div className="min-h-screen">
                {/* Header */}
                <header style={{
                    background: 'rgba(255, 255, 255, 0.8)',
                    backdropFilter: 'blur(10px)',
                    padding: '1rem 1.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    borderBottom: '1px solid rgba(0, 0, 0, 0.05)',
                    position: 'sticky',
                    top: 0,
                    zIndex: 50
                }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <Link href="/dashboard-web/" style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            width: '40px',
                            height: '40px',
                            background: 'var(--surface)',
                            borderRadius: '50%',
                            color: 'var(--text-display)',
                            textDecoration: 'none',
                            boxShadow: 'var(--shadow-card)'
                        }}>
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <line x1="19" y1="12" x2="5" y2="12"></line>
                                <polyline points="12 19 5 12 12 5"></polyline>
                            </svg>
                        </Link>

                        <div className="brand-logo" style={{
                            width: '40px',
                            height: '40px',
                            background: 'linear-gradient(135deg, var(--secondary), var(--quiz))',
                            borderRadius: '50%',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: 'white',
                            fontWeight: 'bold',
                            fontSize: '1.1rem'
                        }}>SV</div>

                        <button onClick={toggleTheme} style={{
                            background: 'transparent',
                            border: 'none',
                            fontSize: '1.2rem',
                            cursor: 'pointer'
                        }}>
                            <span style={{ display: theme === 'day' ? 'none' : 'inline' }}>☀️</span>
                            <span style={{ display: theme === 'night' ? 'none' : 'inline' }}>🌙</span>
                        </button>

                        <h1 style={{ fontSize: '1.2rem', margin: 0 }}>Sakshi Vani</h1>
                    </div>

                    <Link href="/dashboard-web/" style={{
                        width: '40px',
                        height: '40px',
                        background: 'white',
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                    }}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                            <circle cx="12" cy="7" r="4"></circle>
                        </svg>
                    </Link>
                </header>

                {/* Search */}
                <div id="search-container" style={{ padding: '1rem' }}>
                    <input
                        type="text"
                        id="search-input"
                        placeholder="Search songs / गीत खोजें..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        style={{
                            width: '100%',
                            padding: '0.75rem 1rem',
                            borderRadius: '12px',
                            border: '1px solid rgba(0, 0, 0, 0.1)',
                            fontSize: '1rem',
                            background: 'var(--surface)'
                        }}
                    />
                </div>

                {/* Song List */}
                <ul id="song-list" style={{ listStyle: 'none', padding: '0 1rem', margin: 0 }}>
                    {filteredSongs.map(song => (
                        <li
                            key={song.id}
                            className="song-item"
                            onClick={() => showSong(song)}
                            style={{
                                background: 'var(--surface)',
                                padding: '1rem',
                                marginBottom: '0.75rem',
                                borderRadius: '12px',
                                cursor: 'pointer',
                                boxShadow: 'var(--shadow-card)',
                                transition: 'transform 0.2s'
                            }}
                        >
                            <div className="song-title" style={{ fontWeight: 'bold', marginBottom: '0.25rem' }}>
                                {song.id}. {song.title}
                            </div>
                            <div className="song-meta" style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', gap: '1rem' }}>
                                {song.category && <span>{song.category}</span>}
                                {song.reference && <span>{song.reference}</span>}
                            </div>
                        </li>
                    ))}
                    {filteredSongs.length === 0 && (
                        <li style={{ padding: '1rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                            No songs found
                        </li>
                    )}
                </ul>

                {/* Song Detail Modal */}
                {selectedSong && (
                    <div id="song-detail" className="active" style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        background: 'var(--bg-color)',
                        zIndex: 100,
                        overflowY: 'auto'
                    }}>
                        <div className="detail-header" style={{
                            background: 'rgba(255, 255, 255, 0.8)',
                            backdropFilter: 'blur(10px)',
                            padding: '1rem',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '1rem',
                            position: 'sticky',
                            top: 0,
                            zIndex: 10
                        }}>
                            <button
                                onClick={hideSong}
                                className="back-btn"
                                style={{
                                    background: 'none',
                                    border: 'none',
                                    fontSize: '1.5rem',
                                    cursor: 'pointer',
                                    padding: '0.5rem'
                                }}
                            >
                                ←
                            </button>
                            <h1 style={{ flex: 1, fontSize: '1.1rem', margin: 0, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>
                                Song Detail
                            </h1>
                        </div>

                        <div id="detail-content" style={{ padding: '1.5rem' }}>
                            <h2 id="detail-title" style={{ marginBottom: '1.5rem', fontFamily: 'var(--font-heading)' }}>
                                {selectedSong.id}. {selectedSong.title}
                            </h2>
                            <div id="detail-lyrics">
                                {selectedSong.lyrics.split('\n').map((line, i) => {
                                    const trimmed = line.trim()
                                    return trimmed ? (
                                        <div key={i} className="song-line" style={{ marginBottom: '0.5rem', lineHeight: '1.8' }}>
                                            {trimmed}
                                        </div>
                                    ) : (
                                        <br key={i} />
                                    )
                                })}
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </>
    )
}
