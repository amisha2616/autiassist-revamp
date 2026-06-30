import React from 'react';
//import { useState } from 'react'
import './adultQuiz.css'

const quiz = {
  topic: 'Javascript',
  level: 'Beginner',
  totalQuestions: 14,
  perQuestionScore: 5,
  //totalTime: 60, // in seconds
  questions: [
    {
      question:
        'I prefer to do things on my own, rather than with others.',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question:
        'I prefer doing things the same way - for instance my morning routine or trip to the supermarket',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question:
        'I find myself becoming strongly absorbed in something – even obsessional',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'I am very sensitive to noise and will wear earplugs or cover my ears in certain situations',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'Sometimes people say I am being rude, even though I think I am being polite.',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'I find it easy to imagine what characters from a book might look like.',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'I find it easy to talk in groups of people',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'I am more interested in finding out about ‘things’ than people',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'I find numbers, dates and strings of information fascinating',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Slightly Agree',
    },
    {
      question: 'I prefer non-fiction books and films to fiction',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Slightly Agree',
    },
    {
      question: 'I find it upsetting if my daily routine is upset or changed',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely Agree',
    },
    {
      question: 'It’s difficult for me to understand other people’s facial expression and body language',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Slightly disagree',
    },
    {
      question: 'I don’t have any problems making small talk with new people',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Definitely disagree',
    },
    {
      question: 'I notice very small changes in a person’s appearance',
      choices: ['Definitely Agree', 'Slightly Agree', 'Slightly disagree', 'Definitely disagree'],
      type: 'MCQs',
      correctAnswer: 'Slightly Agree',
    },
  ],
}

const Quiz = () => {
  const [activeQuestion, setActiveQuestion] = React.useState(0)
  const [selectedAnswer, setSelectedAnswer] = React.useState('')
  const [showResult, setShowResult] = React.useState(false)
  const [selectedAnswerIndex, setSelectedAnswerIndex] = React.useState(null)
  const [result, setResult] = React.useState({
    score: 0,
    correctAnswers: 0,
    wrongAnswers: 0,
  })

  const { questions } = quiz
  const { question, choices, correctAnswer } = questions[activeQuestion]

  const onClickNext = () => {
    setSelectedAnswerIndex(null)
    setResult((prev) =>
      selectedAnswer
        ? {
          ...prev,
          score: prev.score + 5,
          correctAnswers: prev.correctAnswers + 1,
        }
        : { ...prev, wrongAnswers: prev.wrongAnswers + 1 }
    )
    if (activeQuestion !== questions.length - 1) {
      setActiveQuestion((prev) => prev + 1)
    } else {
      setActiveQuestion(0)
      setShowResult(true)
    }
  }

  const onAnswerSelected = (answer, index) => {
    setSelectedAnswerIndex(index)
    if (answer === correctAnswer) {
      setSelectedAnswer(true)
    } else {
      setSelectedAnswer(false)
    }
  }

  const addLeadingZero = (number) => (number > 9 ? number : `0${number}`)

  return (
    <div className="quiz-container">
      {!showResult ? (
        <div>
          <div>
            <span className="active-question-no">
              {addLeadingZero(activeQuestion + 1)}
            </span>
            <span className="total-question">
              /{addLeadingZero(questions.length)}
            </span>
          </div>
          <h2>{question}</h2>
          <ul>
            {choices.map((answer, index) => (
              <li
                onClick={() => onAnswerSelected(answer, index)}
                key={answer}
                className={
                  selectedAnswerIndex === index ? 'selected-answer' : null
                }
              >
                {answer}
              </li>
            ))}
          </ul>
          <div className="flex-right">
            <button
              onClick={onClickNext}
              disabled={selectedAnswerIndex === null}
            >
              {activeQuestion === questions.length - 1 ? 'Finish' : 'Next'}
            </button>
          </div>
        </div>
      ) : (
        <div className="result">
          <h3>Result</h3>
          <p>
            Total Question: <span>{questions.length}</span>
          </p>
          <p>
            Total Score:<span> {result.score}</span>
          </p>
          <p>
            Correct Answers:<span> {result.correctAnswers}</span>
          </p>
          <p>
            Wrong Answers:<span> {result.wrongAnswers}</span>
          </p>
          <div>
            {(() => {
              if (result.score === 70) {
                return (
                  <div><h2><span className='AdultNonAutistic'>Low likelihood indicators.</span></h2><p>This self-check is not a diagnosis. Consider professional advice if daily life concerns continue.</p></div>
                )
              } else if (result.score < 50) {
                return (
                  <div><h2><span className='AdultHighRisk'>High likelihood indicators.</span></h2><p>This self-check is not a diagnosis. A professional autism assessment or referral is recommended.</p></div>
                )
              } else {
                return (
                  <div><h2><span className='AdultMildAutistic'>Moderate likelihood indicators.</span></h2><p>This self-check is not a diagnosis. Follow-up with a qualified professional is recommended.</p></div>
                )
              }
            })()}
                {/* Legacy diagnostic wording removed. */}

          </div>

        </div>
      )}
    </div>
  )
}


//ReactDOM.render(<Quiz />, document.getElementById('root'));


export default Quiz