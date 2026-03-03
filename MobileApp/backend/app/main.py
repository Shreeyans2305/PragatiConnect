from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

from app.config import settings
from app.routers import auth, profile, chat, schemes, price, business, voice

# Create FastAPI app
app = FastAPI(
    title="PragatiConnect API",
    description="Backend API for PragatiConnect - Economic empowerment for India's informal workforce",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["Profile"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])
app.include_router(voice.router, prefix="/api/v1/voice", tags=["Voice Assistant"])
app.include_router(schemes.router, prefix="/api/v1/schemes", tags=["Schemes"])
app.include_router(price.router, prefix="/api/v1/price", tags=["Price Estimation"])
app.include_router(business.router, prefix="/api/v1/business", tags=["Business Tools"])


@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "PragatiConnect API",
        "version": "1.0.0",
    }


@app.get("/health")
async def health_check():
    """Health check for load balancers."""
    return {"status": "ok"}


# Lambda handler for AWS deployment
handler = Mangum(app, lifespan="off")
