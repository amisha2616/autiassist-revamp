import React, { Component } from 'react';
import axios from 'axios';
import classes from './UploadQuestion.module.css';
import uploadSvg from '../../assets/illustrations/undraw_text_field.svg';
import FooterSection from '../../components/FooterSection/FooterSection';

const mediaTypeByLevel = {
    1: 'image',
    2: 'audio',
    3: 'video'
};

class UploadQuestion extends Component {
    state = {
        question: '',
        level: '1',
        hostedURL: '',
        correct_answer: 'happy',
        incorrect_answers: ['sad', 'angry', 'neutral'],
        options: {
            happy: 'happy',
            sad: 'sad',
            angry: 'angry',
            disgust: 'disgust',
            surprise: 'surprise',
            fear: 'fear',
            crying: 'crying',
            neutral: 'neutral'
        }
    };

    containerRef = React.createRef();
    wrapperRef = React.createRef();
    formRef = React.createRef();

    responseHandler = (message, classname) => {
        const div = document.createElement('div');
        div.className = classname;
        div.style.backgroundColor = classname === 'Danger' ? '#f00946' : '#24ce4a';
        div.style.position = 'absolute';
        div.style.margin = '-40px 0 0 0';
        div.style.width = '100%';
        div.style.color = '#ffffff';
        div.style.padding = '10px';
        div.style.textAlign = 'center';
        div.appendChild(document.createTextNode(message));

        const wrapper = this.wrapperRef.current;
        const form = this.formRef.current;

        wrapper.insertBefore(div, form);
        setTimeout(() => {
            const alert = document.querySelector('.Danger') || document.querySelector('.Success');
            if (alert) alert.remove();
        }, 1500);
    }

    questionHandler = e => {
        this.setState({ question: e.target.value });
    }

    hostedURLHandler = e => {
        this.setState({ hostedURL: e.target.value });
    }

    levelHandler = e => {
        this.setState({ level: e.target.value });
    }

    correctAnswerHandler = e => {
        const correct_answer = e.target.value;
        let incorrect_answers_obj = this.objectWithoutKey(this.state.options, correct_answer);

        const arr = [];
        for (let i = 0; i < 3; i++) {
            let x = this.chooseRandomKey(incorrect_answers_obj);
            arr.push(x);
            incorrect_answers_obj = this.objectWithoutKey(incorrect_answers_obj, x);
        }

        this.setState({
            correct_answer: e.target.value,
            incorrect_answers: arr
        });
    }

    objectWithoutKey = (object, key) => {
        const { [key]: deletedKey, ...otherKeys } = object;
        return otherKeys;
    }

    chooseRandomKey = object => {
        const arr = Object.keys(object);
        return arr[Math.floor(Math.random() * arr.length)];
    }

    submitHandler = e => {
        e.preventDefault();

        const level = Number(this.state.level);
        const ques = {
            level,
            mediaType: mediaTypeByLevel[level],
            question: this.state.question,
            hostedURL: this.state.hostedURL,
            correct_answer: this.state.correct_answer,
            incorrect_answers: this.state.incorrect_answers,
            source: 'manual'
        };

        const shouldUploadQuestion = ques.question.trim() !== '';
        if (!shouldUploadQuestion) {
            this.responseHandler('Question is required.', 'Danger');
            return;
        }

        const patternURL = /^(https?:\/\/|\/).+\.(?:wav|mp3|mp4|webm|ogv|svg|jpeg|jpg|png|gif)$/i;
        const shouldUploadURL = patternURL.test(ques.hostedURL);
        if (!shouldUploadURL) {
            this.responseHandler('Use a valid media URL or public path ending with wav, mp3, mp4, webm, ogv, svg, jpeg, jpg, png, or gif.', 'Danger');
            return;
        }

        axios.post('/api/game-questions', ques)
            .then(() => {
                this.responseHandler('Question added successfully!', 'Success');
                this.setState({ question: '', hostedURL: '' });
            })
            .catch(err => {
                const message = err.response && err.response.data && err.response.data.error
                    ? err.response.data.error
                    : 'Unable to add question.';
                this.responseHandler(message, 'Danger');
            });
    }

    render() {
        return (
            <div ref={this.containerRef} className={classes.Container}>
                <div ref={this.wrapperRef} className={classes.Wrapper}>

                    <form ref={this.formRef} onSubmit={this.submitHandler} className={classes.Form}>
                        <label>Question:</label>
                        <input required value={this.state.question} placeholder={'Question'} onChange={this.questionHandler} type="text" />

                        <label>Level</label>
                        <select name="Level" className={classes.Dropdown} value={this.state.level} onChange={this.levelHandler}>
                            <option value="1">Level 1 - Image</option>
                            <option value="2">Level 2 - Audio</option>
                            <option value="3">Level 3 - Video</option>
                        </select>

                        <label>Hosted URL or public file path:</label>
                        <input required value={this.state.hostedURL} placeholder={'Example: /demo-assets/happy.svg'} onChange={this.hostedURLHandler} type="text" />

                        <label>Correct Answer:</label>
                        <select name="correct-answer" className={classes.Dropdown} onChange={this.correctAnswerHandler}>
                            <option value={this.state.options.happy}>Happy</option>
                            <option value={this.state.options.sad}>Sad</option>
                            <option value={this.state.options.angry}>Angry</option>
                            <option value={this.state.options.fear}>Fear</option>
                            <option value={this.state.options.surprise}>Surprise</option>
                            <option value={this.state.options.disgust}>Disgust</option>
                            <option value={this.state.options.neutral}>Neutral</option>
                            <option value={this.state.options.crying}>Crying</option>
                        </select>

                        <label className={classes.DummyLabel} />

                        <button type="submit" className={classes.SubmitBtn}>Submit</button>
                    </form>
                </div>
                <div className={classes.ImgContainer}>
                    <img alt="Form SVG" src={uploadSvg} />
                </div>
                <FooterSection />
            </div>
        );
    }
}

export default UploadQuestion;
