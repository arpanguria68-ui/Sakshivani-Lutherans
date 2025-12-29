export default function Home() {
    return (
        <div className="min-h-screen flex flex-col items-center justify-center p-5">
            <div className="max-w-4xl w-full text-center">
                {/* Logo */}
                <div className="w-20 h-20 bg-gradient-to-br from-purple-400 to-purple-600 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-lg">
                    <span className="text-4xl font-bold text-white">स</span>
                </div>

                {/* Title */}
                <h1 className="text-5xl font-bold mb-3" style={{ fontFamily: "'Noto Serif Devanagari', serif" }}>
                    साक्षी वाणी
                </h1>
                <p className="text-xl text-gray-600 mb-12 font-medium">
                    Sakshi Vani - Lutheran Hymns & Spiritual Resources
                </p>

                {/* Cards Grid */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                    {/* PWA Card */}
                    <a
                        href="/pwa/"
                        className="bg-white rounded-3xl p-10 flex flex-col items-center gap-5 shadow-md border border-gray-100 hover:-translate-y-2 transition-all duration-300 hover:shadow-xl group"
                    >
                        <div className="w-16 h-16 bg-yellow-100 rounded-2xl flex items-center justify-center">
                            <span className="text-3xl">🎵</span>
                        </div>
                        <h2 className="text-2xl font-bold">Sakshi Vani PWA</h2>
                        <p className="text-gray-600 text-center">
                            Access Lutheran hymns, catechism, and worship resources
                        </p>
                        <ul className="text-left text-sm text-gray-700 space-y-2 w-full">
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                350+ Hindi worship songs
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Complete Luther's Catechism
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Search & favorites
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Works offline
                            </li>
                        </ul>
                        <button className="mt-4 bg-yellow-400 text-gray-900 px-8 py-3 rounded-full font-bold hover:bg-yellow-500 transition-colors">
                            Open PWA →
                        </button>
                    </a>

                    {/* Dashboard Card */}
                    <a
                        href="/dashboard-web/"
                        className="bg-white rounded-3xl p-10 flex flex-col items-center gap-5 shadow-md border border-gray-100 hover:-translate-y-2 transition-all duration-300 hover:shadow-xl group"
                    >
                        <div className="w-16 h-16 bg-purple-100 rounded-2xl flex items-center justify-center">
                            <span className="text-3xl">📖</span>
                        </div>
                        <h2 className="text-2xl font-bold">My Journey</h2>
                        <p className="text-gray-600 text-center">
                            Track your spiritual growth and devotional activities
                        </p>
                        <ul className="text-left text-sm text-gray-700 space-y-2 w-full">
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Prayer tracker
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Bible reading log
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Church attendance
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Daily reflections
                            </li>
                        </ul>
                        <button className="mt-4 bg-purple-500 text-white px-8 py-3 rounded-full font-bold hover:bg-purple-600 transition-colors">
                            Open Dashboard →
                        </button>
                    </a>
                </div>

                {/* Footer */}
                <p className="text-sm text-gray-500 mt-8">
                    Built with ❤️ for the Lutheran community
                </p>
            </div>
        </div>
    )
}
