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
    [bookId: string]: {
        [chapter: string]: {
            [verse: string]: string
        }
    }
}

export default function BibleReaderPage() {
    const [books, setBooks] = useState<Book[]>([])
    const [selectedBookIndex, setSelectedBookIndex] = useState(0)
    const [selectedChapter, setSelectedChapter] = useState(1)
    const [bibleData, setBibleData] = useState<BibleData>({})
    const [language, setLanguage] = useState<'en' | 'hi'>('hi')
    const [isSidebarOpen, setIsSidebarOpen] = useState(true)
    const [searchQuery, setSearchQuery] = useState('')

    // Load books
    useEffect(() => {
        fetch('/dashboard-web/data/bible/books.js')
            .then(res => res.text())
            .then(text => {
                const jsonMatch = text.match(/const books = (\[[\s\S]*\]);/)
                if (jsonMatch) {
                    const booksData = JSON.parse(jsonMatch[1])
                    setBooks(booksData)
                }
            })
            .catch(err => console.error('Error loading books:', err))
    }, [])

    // Load Bible data when language changes
    useEffect(() => {
        const dataFile = language === 'hi' ? 'hi_data.js' : 'en_data.js'
        fetch(`/dashboard-web/data/bible/${dataFile}`)
            .then(res => res.text())
            .then(text => {
                const jsonMatch = text.match(/const bibleData = ({[\s\S]*});/)
                if (jsonMatch) {
                    const data = JSON.parse(jsonMatch[1])
                    setBibleData(data)
                }
            })
            .catch(err => console.error('Error loading Bible data:', err))
    }, [language])

    const selectedBook = books[selectedBookIndex]
    const currentVerses = selectedBook && bibleData[selectedBook.id]?.[selectedChapter]

    const goToPrevChapter = () => {
        if (selectedChapter > 1) {
            setSelectedChapter(selectedChapter - 1)
        } else if (selectedBookIndex > 0) {
            setSelectedBookIndex(selectedBookIndex - 1)
            setSelectedChapter(books[selectedBookIndex - 1].chapters)
        }
    }

    const goToNextChapter = () => {
        if (selectedBook && selectedChapter < selectedBook.chapters) {
            setSelectedChapter(selectedChapter + 1)
        } else if (selectedBookIndex < books.length - 1) {
            setSelectedBookIndex(selectedBookIndex + 1)
            setSelectedChapter(1)
        }
    }

    const filteredBooks = searchQuery
        ? books.filter(book =>
            book.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            book.nameHindi.includes(searchQuery)
        )
        : books

    return (
        <>
            <style jsx global>{`
        @import url('/shared/theme.css');
        body { margin: 0; overflow: hidden; height: 100vh; display: flex; flex-direction: column; }
      `}</style>

            <div style={{ display: 'flex', flexDirection: 'column', height: '100vh' }}>
                {/* Header */}
                <header style={{
                    background: 'rgba(255, 255, 255, 0.8)',
                    backdropFilter: 'blur(10px)',
                    padding: '1rem 1.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    borderBottom: '1px solid rgba(0, 0, 0, 0.05)',
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
                            textDecoration: 'none'
                        }}>
                            ←
                        </Link>
                        <button
                            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
                            style={{
                                background: 'var(--surface)',
                                border: 'none',
                                padding: '8px 12px',
                                borderRadius: '8px',
                                cursor: 'pointer'
                            }}
                        >
                            ☰
                        </button>
                        <h1 style={{ margin: 0, fontSize: '1.2rem' }}>Bible Reader</h1>
                    </div>

                    {/* Language Toggle */}
                    <div style={{ display: 'flex', background: 'white', borderRadius: '100px', padding: '4px', border: '1px solid rgba(0,0,0,0.1)' }}>
                        <button
                            onClick={() => setLanguage('en')}
                            style={{
                                background: language === 'en' ? 'var(--primary)' : 'transparent',
                                border: 'none',
                                padding: '6px 14px',
                                borderRadius: '100px',
                                cursor: 'pointer',
                                fontWeight: 600,
                                fontSize: '13px'
                            }}
                        >
                            EN
                        </button>
                        <button
                            onClick={() => setLanguage('hi')}
                            style={{
                                background: language === 'hi' ? 'var(--primary)' : 'transparent',
                                border: 'none',
                                padding: '6px 14px',
                                borderRadius: '100px',
                                cursor: 'pointer',
                                fontWeight: 600,
                                fontSize: '13px'
                            }}
                        >
                            हिं
                        </button>
                    </div>
                </header>

                {/* Controls Row */}
                <div style={{ padding: '1rem 1.5rem', background: 'var(--bg-color)', borderBottom: '1px solid rgba(0,0,0,0.05)' }}>
                    <div style={{ display: 'flex', gap: '12px', alignItems: 'center', marginBottom: '12px' }}>
                        {/* Book Select */}
                        <select
                            value={selectedBookIndex}
                            onChange={(e) => {
                                setSelectedBookIndex(Number(e.target.value))
                                setSelectedChapter(1)
                            }}
                            style={{
                                flex: 1,
                                padding: '8px 12px',
                                borderRadius: '100px',
                                border: '1px solid rgba(0,0,0,0.1)',
                                background: 'white',
                                fontSize: '14px'
                            }}
                        >
                            {books.map((book, index) => (
                                <option key={book.id} value={index}>
                                    {language === 'hi' ? book.nameHindi : book.name}
                                </option>
                            ))}
                        </select>

                        {/* Chapter Select */}
                        <select
                            value={selectedChapter}
                            onChange={(e) => setSelectedChapter(Number(e.target.value))}
                            style={{
                                padding: '8px 12px',
                                borderRadius: '100px',
                                border: '1px solid rgba(0,0,0,0.1)',
                                background: 'white',
                                fontSize: '14px'
                            }}
                        >
                            {selectedBook && Array.from({ length: selectedBook.chapters }, (_, i) => i + 1).map(ch => (
                                <option key={ch} value={ch}>Chapter {ch}</option>
                            ))}
                        </select>
                    </div>

                    {/* Navigation Buttons */}
                    <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                        <button
                            onClick={goToPrevChapter}
                            disabled={selectedBookIndex === 0 && selectedChapter === 1}
                            style={{
                                padding: '10px',
                                borderRadius: '50%',
                                border: '1px solid rgba(0,0,0,0.05)',
                                background: 'white',
                                cursor: 'pointer',
                                opacity: selectedBookIndex === 0 && selectedChapter === 1 ? 0.5 : 1
                            }}
                        >
                            ←
                        </button>
                        <div style={{ flex: 1, textAlign: 'center', fontWeight: 600 }}>
                            {selectedBook && `${language === 'hi' ? selectedBook.nameHindi : selectedBook.name} ${selectedChapter}`}
                        </div>
                        <button
                            onClick={goToNextChapter}
                            disabled={selectedBookIndex === books.length - 1 && selectedBook && selectedChapter === selectedBook.chapters}
                            style={{
                                padding: '10px',
                                borderRadius: '50%',
                                border: '1px solid rgba(0,0,0,0.05)',
                                background: 'white',
                                cursor: 'pointer',
                                opacity: selectedBookIndex === books.length - 1 && selectedBook && selectedChapter === selectedBook.chapters ? 0.5 : 1
                            }}
                        >
                            →
                        </button>
                    </div>
                </div>

                {/* Main Content */}
                <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
                    {/* Sidebar */}
                    {isSidebarOpen && (
                        <div style={{
                            width: '300px',
                            background: 'rgba(255,255,255,0.7)',
                            backdropFilter: 'blur(10px)',
                            borderRight: '1px solid rgba(0,0,0,0.05)',
                            display: 'flex',
                            flexDirection: 'column'
                        }}>
                            <div style={{ padding: '16px', borderBottom: '1px solid rgba(0,0,0,0.05)' }}>
                                <input
                                    type="text"
                                    placeholder="Search books..."
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                    style={{
                                        width: '100%',
                                        padding: '10px 10px 10px 36px',
                                        borderRadius: '100px',
                                        border: '1px solid rgba(0,0,0,0.1)',
                                        background: 'white'
                                    }}
                                />
                            </div>
                            <div style={{ flex: 1, overflowY: 'auto', padding: '10px' }}>
                                {filteredBooks.map((book, index) => (
                                    <div
                                        key={book.id}
                                        onClick={() => {
                                            setSelectedBookIndex(books.indexOf(book))
                                            setSelectedChapter(1)
                                        }}
                                        style={{
                                            padding: '12px 16px',
                                            cursor: 'pointer',
                                            borderRadius: '8px',
                                            background: selectedBookIndex === books.indexOf(book) ? 'var(--primary)' : 'transparent',
                                            color: selectedBookIndex === books.indexOf(book) ? 'black' : 'var(--text-muted)',
                                            marginBottom: '4px',
                                            fontWeight: 500
                                        }}
                                    >
                                        {language === 'hi' ? book.nameHindi : book.name}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Verse Display */}
                    <div style={{ flex: 1, overflowY: 'auto', padding: '2rem' }}>
                        <div style={{ maxWidth: '800px', margin: '0 auto' }}>
                            <h2 style={{ marginBottom: '2rem', textAlign: 'center', color: 'var(--primary)' }}>
                                {selectedBook && `${language === 'hi' ? selectedBook.nameHindi : selectedBook.name} ${selectedChapter}`}
                            </h2>
                            <div style={{ fontSize: '1.1rem', lineHeight: '2', fontFamily: 'var(--font-heading)' }}>
                                {currentVerses ? (
                                    Object.entries(currentVerses).map(([verse, text]) => (
                                        <p key={verse} style={{ marginBottom: '1.5rem' }}>
                                            <sup style={{ color: 'var(--primary)', fontWeight: 'bold', marginRight: '8px' }}>{verse}</sup>
                                            {text}
                                        </p>
                                    ))
                                ) : (
                                    <p style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Loading verses...</p>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </>
    )
}
