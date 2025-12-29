'use client'

import Link from 'next/link'
import { useState, useEffect } from 'react'

export default function DashboardPage() {
    const [theme, setTheme] = useState('day')

    useEffect(() => {
        // Load theme from localStorage
        const savedTheme = localStorage.getItem('theme') || 'day'
        setTheme(savedTheme)
        document.documentElement.setAttribute('data-theme', savedTheme)
    }, [])

    const toggleTheme = () => {
        const newTheme = theme === 'day' ? 'night' : 'day'
        setTheme(newTheme)
        localStorage.setItem('theme', newTheme)
        document.documentElement.setAttribute('data-theme', newTheme)
    }

    return (
        <div className="min-h-screen pb-20">
            {/* Greeting Section */}
            <div className="bg-gradient-to-r from-indigo-600 to-cyan-400 text-white p-6">
                <div className="flex justify-between items-center mb-5">
                    <div>
                        <h2 className="text-3xl font-bold mb-1">नमस्ते, विश्वासी</h2>
                        <p className="text-sm opacity-90">Welcome back, Believer</p>
                    </div>
                    <button
                        onClick={toggleTheme}
                        className="w-10 h-10 bg-white bg-opacity-20 rounded-full flex items-center justify-center"
                    >
                        {theme === 'day' ? '🌙' : '☀️'}
                    </button>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-3">
                    <div className="bg-white bg-opacity-20 rounded-xl p-3 text-center">
                        <div className="text-2xl font-bold">7</div>
                        <div className="text-xs opacity-90">Day Streak</div>
                    </div>
                    <div className="bg-white bg-opacity-20 rounded-xl p-3 text-center">
                        <div className="text-2xl font-bold">12</div>
                        <div className="text-xs opacity-90">Prayers</div>
                    </div>
                    <div className="bg-white bg-opacity-20 rounded-xl p-3 text-center">
                        <div className="text-2xl font-bold">5</div>
                        <div className="text-xs opacity-90">Chapters</div>
                    </div>
                </div>
            </div>

            {/* Features Grid */}
            <div className="p-5 space-y-4">
                <h3 className="text-lg font-bold text-gray-800">Track Your Journey</h3>

                <div className="grid grid-cols-2 gap-4">
                    {/* Prayer Tracker */}
                    <Link href="/dashboard-web/prayer" className="bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow">
                        <div className="text-3xl mb-2">🙏</div>
                        <h4 className="font-bold text-gray-800 mb-1">Prayer</h4>
                        <p className="text-xs text-gray-600">Log daily prayers</p>
                    </Link>

                    {/* Bible Reading */}
                    <Link href="/dashboard-web/bible" className="bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow">
                        <div className="text-3xl mb-2">📖</div>
                        <h4 className="font-bold text-gray-800 mb-1">Bible</h4>
                        <p className="text-xs text-gray-600">Track reading</p>
                    </Link>

                    {/* Church */}
                    <Link href="/dashboard-web/church" className="bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow">
                        <div className="text-3xl mb-2">⛪</div>
                        <h4 className="font-bold text-gray-800 mb-1">Church</h4>
                        <p className="text-xs text-gray-600">Attendance log</p>
                    </Link>

                    {/* Reflection */}
                    <Link href="/dashboard-web/reflection" className="bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow">
                        <div className="text-3xl mb-2">✍️</div>
                        <h4 className="font-bold text-gray-800 mb-1">Reflect</h4>
                        <p className="text-xs text-gray-600">Daily thoughts</p>
                    </Link>

                    {/* Quiz */}
                    <Link href="/dashboard-web/quiz" className="bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow">
                        <div className="text-3xl mb-2">🎯</div>
                        <h4 className="font-bold text-gray-800 mb-1">Quiz</h4>
                        <p className="text-xs text-gray-600">Test knowledge</p>
                    </Link>

                    {/* Sakshi Vani */}
                    <Link href="/pwa/" className="bg-gradient-to-br from-yellow-400 to-orange-400 rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow text-white">
                        <div className="text-3xl mb-2">🎵</div>
                        <h4 className="font-bold mb-1">Sakshi Vani</h4>
                        <p className="text-xs opacity-90">Hymns & Songs</p>
                    </Link>
                </div>
            </div>
        </div>
    )
}
