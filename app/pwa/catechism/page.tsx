'use client'

import Link from 'next/link'

const catechismChapters = [
    { id: 1, title: 'The Ten Commandments', subtitle: 'दस आज्ञाएँ', icon: '📜' },
    { id: 2, title: 'The Apostles\' Creed', subtitle: 'प्रेरितों का विश्वास-कथन', icon: '✝️' },
    { id: 3, title: 'The Lord\'s Prayer', subtitle: 'प्रभु की प्रार्थना', icon: '🙏' },
    { id: 4, title: 'Holy Baptism', subtitle: 'पवित्र बपतिस्मा', icon: '💧' },
    { id: 5, title: 'Holy Communion', subtitle: 'पवित्र भोज', icon: '🍞' },
    { id: 6, title: 'Confession', subtitle: 'पाप-स्वीकार', icon: '💬' },
]

export default function CatechismPage() {
    return (
        <div className="min-h-screen bg-gray-50 pb-20">
            {/* Header */}
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/pwa/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <div className="w-10 h-10 bg-gradient-to-br from-purple-400 to-blue-500 rounded-full flex items-center justify-center text-white font-bold">
                        C
                    </div>
                    <h1 className="text-xl font-bold">धर्मशिक्षा (Catechism)</h1>
                </div>
                <Link href="/dashboard-web/" className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-md">
                    👤
                </Link>
            </header>

            {/* Chapters List */}
            <div className="p-5 space-y-4">
                <h2 className="text-lg font-bold text-gray-800 mb-4">Luther's Small Catechism</h2>

                {catechismChapters.map(chapter => (
                    <Link
                        key={chapter.id}
                        href={`/pwa/catechism/${chapter.id}`}
                        className="block bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow"
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-14 h-14 bg-gradient-to-br from-purple-100 to-blue-100 rounded-xl flex items-center justify-center text-3xl flex-shrink-0">
                                {chapter.icon}
                            </div>
                            <div className="flex-1">
                                <h3 className="font-bold text-gray-800 mb-1">{chapter.title}</h3>
                                <p className="text-sm text-gray-600">{chapter.subtitle}</p>
                            </div>
                            <div className="text-gray-400">→</div>
                        </div>
                    </Link>
                ))}
            </div>

            {/* Bottom Navigation */}
            <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-4">
                <div className="flex justify-around">
                    <Link href="/pwa/" className="flex flex-col items-center text-gray-600">
                        <span className="text-2xl">🎵</span>
                        <span className="text-xs">Songs</span>
                    </Link>
                    <Link href="/pwa/catechism" className="flex flex-col items-center text-purple-500">
                        <span className="text-2xl">📚</span>
                        <span className="text-xs">Catechism</span>
                    </Link>
                </div>
            </div>
        </div>
    )
}
