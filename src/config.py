# Fully implement the `config` module
config = {
    'paths': {
        'preprocessor_filename': 'models/preprocessor.pkl',
        'model_filename': 'models/model.pkl',
        'data_raw': 'data/raw/data.csv',
        'data_processed': 'data/processed/data.csv'
    },
    'data': {
        'test_size': 0.2,  # Correct type: float
        'random_state': 42,  # Correct type: int
        'target_column': 'target',
        'expected_columns': ['feature1', 'feature2', 'feature3', 'target']
    },
    'api': {
        'version': '/v1',
        'host': '0.0.0.0',
        'port': 8000
    },
    'project': {
        'name': 'omnitide-ai-suite',
        'description': 'An intelligent, self-healing MLOps platform.'
    }
}
