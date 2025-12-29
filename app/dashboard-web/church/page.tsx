'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function ChurchPage() {
    const router = useRouter()
    const [selectedService, setSelectedService] = useState('sunday')
    const [selectedRole, setSelectedRole] = useState('attendee')

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()

        const churchLog = {
            service: selectedService,
            role: selectedRole,
            date: new Date().toISOString()
        }

        const logs = JSON.parse(localStorage.getItem('churchLogs') || '[]')
        logs.push(churchLog)
        localStorage.setItem('churchLogs', JSON.stringify(logs))

        alert('Church attendance logged! ⛪')
        router.push('/dashboard-web/')
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <h1 className="text-xl font-bold">चर्च उपस्थिति</h1>
                </div>
                <button className="text-2xl">☀️</button>
            </header>

            <form onSubmit={handleSubmit} className="p-6 max-w-2xl mx-auto">
                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <div className="mb-6">
                        <label className="block font-semibold mb-3">Service Type</label>
                        <div className="grid grid-cols-2 gap-3">
                            {['sunday', 'midweek', 'special'].map(service => (
                                <button
                                    key={service}
                                    type="button"
                                    onClick={() => setSelectedService(service)}
                                    className={`p-3 rounded-xl border-2 capitalize ${selectedService === service
                                            ? 'bg-yellow-400 border-yellow-400 text-gray-900'
                                            : 'bg-gray-50 border-gray-200'
                                        }`}
                                >
                                    {service}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="mb-6">
                        <label className="block font-semibold mb-3">Your Role</label>
                        <div className="grid grid-cols-2 gap-3">
                            {['attendee', 'volunteer', 'leader'].map(role => (
                                <button
                                    key={role}
                                    type="button"
                                    onClick={() => setSelectedRole(role)}
                                    className={`p-3 rounded-xl border-2 capitalize ${selectedRole === role
                                            ? 'bg-yellow-400 border-yellow-400 text-gray-900'
                                            : 'bg-gray-50 border-gray-200'
                                        }`}
                                >
                                    {role}
                                </button>
                            ))}
                        </div>
                    </div>

                    <button
                        type="submit"
                        className="w-full bg-yellow-400 text-gray-900 py-4 rounded-xl font-bold text-lg hover:bg-yellow-500 transition-colors shadow-lg"
                    >
                        Log Attendance
                    </button>
                </div>
            </form>
        </div>
    )
}
