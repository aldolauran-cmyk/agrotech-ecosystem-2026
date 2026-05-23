from sqlalchemy import Column, Integer, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime

from backend.app.core.database import Base


class Telemetry(Base):
    __tablename__ = "telemetry"

    id = Column(Integer, primary_key=True, index=True)

    humidity = Column(Float, nullable=False)
    temperature = Column(Float, nullable=False)
    ph = Column(Float, nullable=False)

    timestamp = Column(DateTime, default=datetime.utcnow)

    parcel_id = Column(Integer, ForeignKey("parcels.id"), nullable=False)

    parcel = relationship("Parcel")