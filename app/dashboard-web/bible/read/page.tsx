'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'

interface Book {
    id: string
    name: string
    nameHindi: string
    chapters: number
    testament: string
}

interface BibleData {
    [key: string]: {
        [chapter: string]: {
            [verse: string]: string
        }
    }
}

export default function BibleReaderPage() {
    const [books, setBooks] = useState<Book[]>([])
    const [selectedBook, setSelectedBook] = useState<string>('')
    const [selectedChapter, setSelectedChapter] = useState<number>(1)
    const [bibleData, setBibleData] = useState<BibleData>({})
    const [currentText, setCurrentText] = useState<string>('')
    const [language, setLanguage] = useState<'en' | 'hi'>('hi')

    useEffect(() => {
        // Load books list
        fetch('/dashboard-web/data/bible/books.js')
            .then(res => res.text())
            .then(text => {
                // Extract JSON from the JS file
                const jsonMatch = text.match(/const books = (\[[\s\S]*\]);/)
                if (jsonMatch) {
                    const booksData = JSON.parse(jsonMatch[1])
                    setBooks(booksData)
                    if (booksData.length > 0) {
                        setSelectedBook(booksData[0].id)
                    }
                }
            })
            .catch(err => console.error('Error loading books:', err))
    }, [])

    useEffect(() => {
        // Load Bible data when language changes
        const dataFile = language === 'hi' ? 'hi_data.js' : 'en_data.js'
        fetch(`/dashboard-web/data/bible/${dataFile}`)
            .then(res => res.text())
            .then(text => {
                // Extract JSON from the JS file
                const jsonMatch = text.match(/const bibleData = ({[\s\S]*});/)
                if (jsonMatch) {
                    const data = JSON.parse(jsonMatch[1])
                    setBibleData(data)
                }
            })
            .catch(err => console.error('Error loading Bible data:', err))
    }, [language])

    useEffect(() => {
        // Update current text when book/chapter changes
        if (selectedBook && bibleData[selectedBook]) {
            const chapterData = bibleData[selectedBook][selectedChapter]
            if (chapterData) {
                const verses = Object.entries(chapterData)
                    .map(([verse, text]) => `${verse}. ${text}`)
                    .join('\n\n')
                setCurrentText(verses)
            }
        }
    }, [selectedBook, selectedChapter, bibleData])

    const selectedBookData = books.find(b => b.id === selectedBook)
    const maxChapters = selectedBookData?.chapters || 1

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white sticky top-0 z-50 shadow-sm">
                <div className="p-4 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                            ←
                        </Link>
                        <h1 className="text-xl font-bold">Bible Reader</h1>
                    </div>
                    <button
                        onClick={() => setLanguage(language === 'hi' ? 'en' : 'hi')}
                        className="px-4 py-2 bg-blue-500 text-white rounded-lg font-semibold"
                    >
                        {language === 'hi' ? 'हिंदी' : 'English'}
                    </button>
                </div>

                {/* Book Selector */}
                <div className="px-4 pb-4">
                    <select
                        value={selectedBook}
                        onChange={(e) => {
                            setSelectedBook(e.target.value)
                            setSelectedChapter(1)
                        }}
                        className="w-full p-3 rounded-xl border-2 border-gray-200 bg-white font-semibold"
                    >
                        {books.map(book => (
                            <option key={book.id} value={book.id}>
                                {language === 'hi' ? book.nameHindi : book.name}
                            </option>
                        ))}
                    </select>
                </div>

                {/* Chapter Selector */}
                <div className="px-4 pb-4">
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => setSelectedChapter(Math.max(1, selectedChapter - 1))}
                            disabled={selectedChapter === 1}
                            className="px-4 py-2 bg-gray-200 rounded-lg font-bold disabled:opacity-50"
                        >
                            ←
                        </button>
                        <select
                            value={selectedChapter}
                            onChange={(e) => setSelectedChapter(Number(e.target.value))}
                            className="flex-1 p-3 rounded-xl border-2 border-gray-200 bg-white font-semibold text-center"
                        >
                            {Array.from({ length: maxChapters }, (_, i) => i + 1).map(ch => (
                                <option key={ch} value={ch}>
                                    Chapter {ch}
                                </option>
                            ))}
                        </select>
                        <button
                            onClick={() => setSelectedChapter(Math.min(maxChapters, selectedChapter + 1))}
                            disabled={selectedChapter === maxChapters}
                            className="px-4 py-2 bg-gray-200 rounded-lg font-bold disabled:opacity-50"
                        >
                            →
                        </button>
                    </div>
                </div>
            </header>

            {/* Bible Text */}
            <div className="p-6 max-w-4xl mx-auto">
                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <h2 className="text-2xl font-bold mb-4 text-center text-blue-600">
                        {selectedBookData && (language === 'hi' ? selectedBookData.nameHindi : selectedBookData.name)} {selectedChapter}
                    </h2>
                    <div className="prose prose-lg max-w-none">
                        {currentText.split('\n\n').map((verse, idx) => (
                            <p key={idx} className="mb-4 leading-relaxed text-gray-800">
                                {verse}
                            </p>
                        ))}
                    </div>
                    {!currentText && (
                        <p className="text-center text-gray-500 py-8">
                            Loading Bible text...
                        </p>
                    )}
                </div>
            </div>
        </div>
    )
}
