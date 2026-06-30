import React from 'react';
import Level from '../../../containers/Level/Level';

const API_URL = '/api/game-questions?level=2';
const LEVEL = 2;

const level2 = () => {
    return <Level level={LEVEL} url={API_URL} />;
}

export default level2;
