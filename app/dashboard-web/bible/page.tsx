'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function BiblePage() {
    const router = useRouter()
    const [book, setBook] = useState('')
    const [chapters, setChapters] = useState('')
    const [testament, setTestament] = useState('old')
    const [notes, setNotes] = useState('')

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()

        const bibleLog = {
            book,
            chapters,
            testament,
            notes,
            date: new Date().toISOString()
        }

        const logs = JSON.parse(localStorage.getItem('bibleLogs') || '[]')
        logs.push(bibleLog)
        localStorage.setItem('bibleLogs', JSON.stringify(logs))

        alert('Bible reading logged! 📖')
        router.push('/dashboard-web/')
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <h1 className="text-xl font-bold">बाइबल पढ़ना लॉग करें</h1>
                </div>
                <button className="text-2xl">☀️</button>
            </header>

            <form onSubmit={handleSubmit} className="p-6 max-w-2xl mx-auto">
                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <div className="mb-4">
                        <label className="block font-semibold mb-2">Book / पुस्तक</label>
                        <input
                            type="text"
                            value={book}
                            onChange={(e) => setBook(e.target.value)}
                            placeholder="e.g., यूहन्ना (John)"
                            required
                            className="w-full p-3 rounded-xl border-2 border-gray-200 focus:border-blue-400 focus:outline-none"
                        />
                    </div>

                    <div className="mb-4">
                        <label className="block font-semibold mb-2">Chapters / अध्याय</label>
                        <input
                            type="text"
                            value={chapters}
                            onChange={(e) => setChapters(e.target.value)}
                            placeholder="e.g., 3:16-21"
                            required
                            className="w-full p-3 rounded-xl border-2 border-gray-200 focus:border-blue-400 focus:outline-none"
                        />
                    </div>

                    <div className="mb-4">
                        <label className="block font-semibold mb-2">Testament / नियम</label>
                        <div className="flex gap-3">
                            <button
                                type="button"
                                onClick={() => setTestament('old')}
                                className={`flex-1 p-3 rounded-xl border-2 ${testament === 'old'
                                    ? 'bg-blue-500 border-blue-500 text-white'
                                    : 'bg-gray-50 border-gray-200'
                                    }`}
                            >
                                Old Testament
                            </button>
                            <button
                                type="button"
                                onClick={() => setTestament('new')}
                                className={`flex-1 p-3 rounded-xl border-2 ${testament === 'new'
                                    ? 'bg-blue-500 border-blue-500 text-white'
                                    : 'bg-gray-50 border-gray-200'
                                    }`}
                            >
                                New Testament
                            </button>
                        </div>
                    </div>

                    <div className="mb-6">
                        <label className="block font-semibold mb-2">Notes (Optional) / टिप्पणी</label>
                        <textarea
                            value={notes}
                            onChange={(e) => setNotes(e.target.value)}
                            placeholder="Any insights or reflections..."
                            rows={4}
                            className="w-full p-3 rounded-xl border-2 border-gray-200 focus:border-blue-400 focus:outline-none resize-none"
                        />
                    </div>

                    <div className="bg-gradient-to-r from-purple-50 to-blue-50 rounded-xl p-5 border-l-4 border-blue-500 mb-6">
                        <p className="text-gray-800 italic mb-2">
                            "तेरा वचन मेरे पैरों के लिए दीपक और मेरे मार्ग के लिए प्रकाश है।"
                        </p>
                        <cite className="text-sm text-gray-600 font-semibold">- भजन संहिता 119:105</cite>
                    </div>

                    <button
                        type="submit"
                        className="w-full bg-blue-500 text-white py-4 rounded-xl font-bold text-lg hover:bg-blue-600 transition-colors shadow-lg"
                    >
                        Log Reading
                    </button>

                    <Link
                        href="/dashboard-web/bible/read"
                        className="block w-full bg-green-500 text-white py-4 rounded-xl font-bold text-lg hover:bg-green-600 transition-colors shadow-lg text-center mt-3"
                    >
                        📖 Read Bible Now
                    </Link>
                </div>
            </form>
        </div>
    )
}
