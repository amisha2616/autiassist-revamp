import React from 'react';
import Level from '../../../containers/Level/Level';

const API_URL = '/api/game-questions?level=3';
const LEVEL = 3;

const level3 = () => {
    return <Level level={LEVEL} url={API_URL} />;
}

export default level3;
