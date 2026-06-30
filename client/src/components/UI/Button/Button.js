import React from 'react';
import './Button.css';

const STYLES = [
    'PrimaryBtn', 'OutlineBtn',
];

const SIZES = [
    'MediumBtn', 'LargeBtn', 'MobileBtn', 'WideBtn'
];

const COLORS = [
    'PrimaryClr', 'BlueClr', 'RedClr', 'GreenClr'
];

const button = props => {

    const checkButtonStyle = STYLES.includes(props.buttonStyle) ?
        `${props.buttonStyle}` : STYLES[0];

    const checkButtonSize = SIZES.includes(props.buttonSize) ?
        `${props.buttonSize}` : SIZES[0];

    const checkButtonColor = COLORS.includes(props.buttonColor) ?
        `${props.buttonColor}` : COLORS[0];


    return (
        <button
            className={`Btn ${checkButtonStyle} ${checkButtonSize} ${checkButtonColor}`}
        >{props.children}
        </button >
    )
}

export default button;