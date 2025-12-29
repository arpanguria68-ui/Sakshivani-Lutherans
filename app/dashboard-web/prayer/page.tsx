'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function PrayerPage() {
    const router = useRouter()
    const [selectedTime, setSelectedTime] = useState('morning')
    const [selectedType, setSelectedType] = useState('thanksgiving')

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()

        // Save to localStorage
        const prayerLog = {
            time: selectedTime,
            type: selectedType,
            date: new Date().toISOString()
        }

        const logs = JSON.parse(localStorage.getItem('prayerLogs') || '[]')
        logs.push(prayerLog)
        localStorage.setItem('prayerLogs', JSON.stringify(logs))

        alert('Prayer logged successfully! 🙏')
        router.push('/dashboard-web/')
    }

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <h1 className="text-xl font-bold">प्रार्थना लॉग करें</h1>
                </div>
                <button className="text-2xl">☀️</button>
            </header>

            {/* Form */}
            <form onSubmit={handleSubmit} className="p-6 max-w-2xl mx-auto">
                <div className="bg-white rounded-2xl p-6 shadow-md mb-6">
                    {/* Time Selection */}
                    <div className="mb-6">
                        <label className="block font-semibold mb-3 text-gray-800">समय (Time)</label>
                        <div className="flex gap-3">
                            <button
                                type="button"
                                onClick={() => setSelectedTime('morning')}
                                className={`flex-1 p-3 rounded-xl border-2 transition-all ${selectedTime === 'morning'
                                        ? 'bg-indigo-600 border-indigo-600 text-white shadow-lg'
                                        : 'bg-gray-50 border-gray-200 text-gray-700'
                                    }`}
                            >
                                Morning
                            </button>
                            <button
                                type="button"
                                onClick={() => setSelectedTime('evening')}
                                className={`flex-1 p-3 rounded-xl border-2 transition-all ${selectedTime === 'evening'
                                        ? 'bg-indigo-600 border-indigo-600 text-white shadow-lg'
                                        : 'bg-gray-50 border-gray-200 text-gray-700'
                                    }`}
                            >
                                Evening
                            </button>
                        </div>
                    </div>

                    {/* Type Selection */}
                    <div className="mb-6">
                        <label className="block font-semibold mb-3 text-gray-800">प्रार्थना का प्रकार (Type)</label>
                        <div className="grid grid-cols-2 gap-3">
                            {['thanksgiving', 'intercessory', 'repentance'].map(type => (
                                <button
                                    key={type}
                                    type="button"
                                    onClick={() => setSelectedType(type)}
                                    className={`p-3 rounded-xl border-2 transition-all capitalize ${selectedType === type
                                            ? 'bg-indigo-600 border-indigo-600 text-white shadow-lg'
                                            : 'bg-gray-50 border-gray-200 text-gray-700'
                                        }`}
                                >
                                    {type}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Verse Quote */}
                    <div className="bg-gradient-to-r from-purple-50 to-blue-50 rounded-xl p-5 border-l-4 border-indigo-600 mb-6">
                        <p className="text-gray-800 italic mb-2 leading-relaxed">
                            "प्रार्थना में फलदायी रहो और धन्यवाद के साथ उसमें जागते रहो।"
                        </p>
                        <cite className="text-sm text-gray-600 font-semibold">- कुलुस्सियों 4:2</cite>
                    </div>

                    {/* Submit Button */}
                    <button
                        type="submit"
                        className="w-full bg-indigo-600 text-white py-4 rounded-xl font-bold text-lg hover:bg-indigo-700 transition-colors shadow-lg"
                    >
                        Log Prayer
                    </button>
                </div>
            </form>
        </div>
    )
}
