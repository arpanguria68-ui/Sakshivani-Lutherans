'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function ReflectionPage() {
    const router = useRouter()
    const [selectedMood, setSelectedMood] = useState('')
    const [title, setTitle] = useState('')
    const [reflection, setReflection] = useState('')

    const moods = [
        { emoji: '😊', label: 'Joyful' },
        { emoji: '😌', label: 'Peaceful' },
        { emoji: '😔', label: 'Struggling' },
        { emoji: '🙏', label: 'Grateful' },
    ]

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()

        if (!selectedMood) {
            alert('Please select how you\'re feeling today')
            return
        }

        const reflectionLog = {
            mood: selectedMood,
            title: title || 'Untitled Reflection',
            reflection,
            date: new Date().toISOString()
        }

        const logs = JSON.parse(localStorage.getItem('reflectionLogs') || '[]')
        logs.push(reflectionLog)
        localStorage.setItem('reflectionLogs', JSON.stringify(logs))

        alert('Reflection saved! ✍️')
        router.push('/dashboard-web/')
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <h1 className="text-xl font-bold">दैनिक चिंतन</h1>
                </div>
                <button className="text-2xl">☀️</button>
            </header>

            <form onSubmit={handleSubmit} className="p-6 max-w-2xl mx-auto">
                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <div className="mb-6">
                        <label className="block font-semibold mb-3">How are you feeling today?</label>
                        <div className="grid grid-cols-4 gap-3">
                            {moods.map(mood => (
                                <button
                                    key={mood.label}
                                    type="button"
                                    onClick={() => setSelectedMood(mood.label)}
                                    className={`p-4 rounded-xl border-2 flex flex-col items-center gap-2 ${selectedMood === mood.label
                                            ? 'bg-orange-100 border-orange-400'
                                            : 'bg-gray-50 border-gray-200'
                                        }`}
                                >
                                    <span className="text-3xl">{mood.emoji}</span>
                                    <span className="text-xs">{mood.label}</span>
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="mb-4">
                        <label className="block font-semibold mb-2">Title (Optional)</label>
                        <input
                            type="text"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="Give your reflection a title..."
                            className="w-full p-3 rounded-xl border-2 border-gray-200 focus:border-orange-400 focus:outline-none"
                        />
                    </div>

                    <div className="mb-6">
                        <label className="block font-semibold mb-2">Your Reflection</label>
                        <textarea
                            value={reflection}
                            onChange={(e) => setReflection(e.target.value)}
                            placeholder="What's on your heart today?..."
                            rows={6}
                            required
                            className="w-full p-3 rounded-xl border-2 border-gray-200 focus:border-orange-400 focus:outline-none resize-none"
                        />
                    </div>

                    <button
                        type="submit"
                        className="w-full bg-orange-500 text-white py-4 rounded-xl font-bold text-lg hover:bg-orange-600 transition-colors shadow-lg"
                    >
                        Save Reflection
                    </button>
                </div>
            </form>
        </div>
    )
}
