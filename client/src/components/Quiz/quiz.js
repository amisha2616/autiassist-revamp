import React from 'react';
//import { useState } from 'react'
import './quiz.css'
// import Video from "../../assets/videos/Video.mp4"
// import ReactPlayer from "react-player";

const quiz = {
  topic: 'Javascript',
  level: 'Beginner',
  totalQuestions: 14,
  perQuestionScore: 5,
  //totalTime: 60, // in seconds
  questions: [
    {
      question:
        'If you point at something across the  room, does your child look at it?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question:
        'Have you ever wondered if your child  might be deaf?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'No',
    },
    {
      question:
        'Does your child play pretend or  make-believe?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'No',
    },
    {
      question: 'Does your child like climbing on things?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: 'Does your child make unusual finger  movements near his or her eyes?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'No',
    },
    {
      question: 'Does your child point with one finger to  ask for something or to get help?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: ' Does your child interact with other  children?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: ' Does your child respond when you call  his or her name?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: 'Does your child use between 1 and 3 words?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: 'Does your child understand simple instructions, such as "Where’s teddy?”',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'No',
    },
    {
      question: 'Does your child look you in the eye when you are talking to him or her?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: 'Does your child try to copy what you do?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: 'If you turn your head to look at something, does your child look around to see what you are looking at?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
    },
    {
      question: 'Does your child understand when you tell him or her to do something?',
      choices: ['Yes', 'No'],
      type: 'MCQs',
      correctAnswer: 'Yes',
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
    <div className='quiz-main-continer'>
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
                    <div><h2><span className='nonAutistic'>Low likelihood indicators.</span></h2><p>This screening result is not a diagnosis. Continue regular developmental monitoring.</p></div>
                  )
                } else if (result.score < 50) {
                  return (
                    <div><h2><span className='highRisk'>High likelihood indicators.</span></h2><p>This screening result is not a diagnosis. A professional developmental evaluation is recommended.</p></div>
                  )
                } else {
                  return (
                    <div><h2><span className='mildAutistic'>Moderate likelihood indicators.</span></h2><p>This screening result is not a diagnosis. Follow-up questions or professional consultation are recommended.</p></div>
                  )
                }
              })()}
                {/* Legacy diagnostic wording removed. */}

            </div>
          </div>
        )}
      </div>
      {/* <div style={{ marginTop: '10rem', marginLeft: '11.5rem' }}>
        <video src={Video} width="750" height="500" autoPlay loop>
        </video>
      </div> */}
    </div>
  )
}


//ReactDOM.render(<Quiz />, document.getElementById('root'));


export default Quiz