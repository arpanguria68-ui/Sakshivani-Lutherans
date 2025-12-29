'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'

interface Song {
    id: number
    title: string
    lyrics: string
}

export default function PWAPage() {
    const [songs, setSongs] = useState<Song[]>([])
    const [searchTerm, setSearchTerm] = useState('')
    const [filteredSongs, setFilteredSongs] = useState<Song[]>([])

    useEffect(() => {
        // Load songs from JSON
        fetch('/pwa/songs.json')
            .then(res => res.json())
            .then(data => {
                setSongs(data)
                setFilteredSongs(data)
            })
            .catch(err => console.error('Error loading songs:', err))
    }, [])

    useEffect(() => {
        if (searchTerm) {
            const filtered = songs.filter(song =>
                song.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                song.lyrics.toLowerCase().includes(searchTerm.toLowerCase())
            )
            setFilteredSongs(filtered)
        } else {
            setFilteredSongs(songs)
        }
    }, [searchTerm, songs])

    return (
        <div className="min-h-screen pb-20">
            {/* Header */}
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        <span>←</span>
                    </Link>
                    <div className="w-10 h-10 bg-gradient-to-br from-yellow-400 to-orange-400 rounded-full flex items-center justify-center text-white font-bold">
                        SV
                    </div>
                    <h1 className="text-xl font-bold">Sakshi Vani</h1>
                </div>
                <Link href="/dashboard-web/" className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-md">
                    <span>👤</span>
                </Link>
            </header>

            {/* Search */}
            <div className="p-4">
                <input
                    type="text"
                    placeholder="Search songs / गीत खोजें..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full p-4 rounded-2xl bg-white shadow-md border border-gray-200 focus:outline-none focus:ring-2 focus:ring-yellow-400"
                />
            </div>

            {/* Songs List */}
            <div className="px-4 space-y-3">
                {filteredSongs.map(song => (
                    <Link
                        key={song.id}
                        href={`/pwa/song/${song.id}`}
                        className="block bg-white rounded-2xl p-4 shadow-md hover:shadow-lg transition-shadow"
                    >
                        <h3 className="font-bold text-gray-800 mb-1">{song.title}</h3>
                        <p className="text-sm text-gray-600 line-clamp-2">{song.lyrics.substring(0, 100)}...</p>
                    </Link>
                ))}
            </div>

            {/* Quick Links */}
            <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-4">
                <div className="flex justify-around">
                    <Link href="/pwa/" className="flex flex-col items-center text-yellow-500">
                        <span className="text-2xl">🎵</span>
                        <span className="text-xs">Songs</span>
                    </Link>
                    <Link href="/pwa/catechism" className="flex flex-col items-center text-gray-600">
                        <span className="text-2xl">📚</span>
                        <span className="text-xs">Catechism</span>
                    </Link>
                </div>
            </div>
        </div>
    )
}
