'use client'

import { useState } from 'react'
import Link from 'next/link'

const quizQuestions = [
    {
        question: "Who wrote the Gospel of John?",
        options: ["Matthew", "Mark", "Luke", "John"],
        correct: 3
    },
    {
        question: "How many commandments did God give Moses?",
        options: ["5", "10", "12", "15"],
        correct: 1
    },
    {
        question: "What is the first book of the Bible?",
        options: ["Exodus", "Genesis", "Leviticus", "Numbers"],
        correct: 1
    }
]

export default function QuizPage() {
    const [currentQuestion, setCurrentQuestion] = useState(0)
    const [score, setScore] = useState(0)
    const [showResult, setShowResult] = useState(false)
    const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null)

    const handleAnswer = (index: number) => {
        setSelectedAnswer(index)

        if (index === quizQuestions[currentQuestion].correct) {
            setScore(score + 1)
        }

        setTimeout(() => {
            if (currentQuestion < quizQuestions.length - 1) {
                setCurrentQuestion(currentQuestion + 1)
                setSelectedAnswer(null)
            } else {
                setShowResult(true)
            }
        }, 1000)
    }

    const resetQuiz = () => {
        setCurrentQuestion(0)
        setScore(0)
        setShowResult(false)
        setSelectedAnswer(null)
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <header className="bg-white bg-opacity-90 backdrop-blur-md sticky top-0 z-50 p-4 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link href="/dashboard-web/" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <h1 className="text-xl font-bold">Bible Quiz</h1>
                </div>
                <div className="text-sm font-semibold text-gray-600">
                    {currentQuestion + 1} / {quizQuestions.length}
                </div>
            </header>

            <div className="p-6 max-w-2xl mx-auto">
                {!showResult ? (
                    <div className="bg-white rounded-2xl p-6 shadow-md">
                        <h2 className="text-2xl font-bold mb-6 text-gray-800">
                            {quizQuestions[currentQuestion].question}
                        </h2>

                        <div className="space-y-3">
                            {quizQuestions[currentQuestion].options.map((option, index) => (
                                <button
                                    key={index}
                                    onClick={() => handleAnswer(index)}
                                    disabled={selectedAnswer !== null}
                                    className={`w-full p-4 rounded-xl border-2 text-left font-medium transition-all ${selectedAnswer === null
                                            ? 'bg-gray-50 border-gray-200 hover:border-purple-400 hover:bg-purple-50'
                                            : selectedAnswer === index
                                                ? index === quizQuestions[currentQuestion].correct
                                                    ? 'bg-green-100 border-green-500 text-green-800'
                                                    : 'bg-red-100 border-red-500 text-red-800'
                                                : index === quizQuestions[currentQuestion].correct
                                                    ? 'bg-green-100 border-green-500 text-green-800'
                                                    : 'bg-gray-50 border-gray-200'
                                        }`}
                                >
                                    {option}
                                </button>
                            ))}
                        </div>
                    </div>
                ) : (
                    <div className="bg-white rounded-2xl p-8 shadow-md text-center">
                        <div className="text-6xl mb-4">
                            {score === quizQuestions.length ? '🎉' : score >= quizQuestions.length / 2 ? '👍' : '📚'}
                        </div>
                        <h2 className="text-3xl font-bold mb-2">Quiz Complete!</h2>
                        <p className="text-xl text-gray-600 mb-6">
                            You scored {score} out of {quizQuestions.length}
                        </p>
                        <div className="flex gap-3">
                            <button
                                onClick={resetQuiz}
                                className="flex-1 bg-purple-500 text-white py-3 rounded-xl font-bold hover:bg-purple-600 transition-colors"
                            >
                                Try Again
                            </button>
                            <Link
                                href="/dashboard-web/"
                                className="flex-1 bg-gray-200 text-gray-800 py-3 rounded-xl font-bold hover:bg-gray-300 transition-colors flex items-center justify-center"
                            >
                                Back to Dashboard
                            </Link>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}
