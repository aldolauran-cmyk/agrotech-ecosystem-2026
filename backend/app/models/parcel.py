from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from datetime import datetime

from backend.app.core.database import Base


class Parcel(Base):
    __tablename__ = "parcels"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    ubicacion_grilla = Column(String, nullable=False)
    ubicacion_referencial = Column(String, nullable=False)
    soil_type = Column(String, nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    owner = relationship("User", back_populates="parcels")
    telemetries = relationship("Telemetry", back_populates="parcel", order_by="desc(Telemetry.timestamp)", cascade="all, delete-orphan")

    @property
    def moisture(self) -> float:
        if self.telemetries:
            return self.telemetries[0].humidity
        return 0.0

    @property
    def ph(self) -> float:
        if self.telemetries:
            return self.telemetries[0].ph
        return 7.0

    @property
    def temperature(self) -> float:
        if self.telemetries:
            return self.telemetries[0].temperature
        return 20.0

    @property
    def has_water_stress(self) -> bool:
        if self.telemetries:
            return self.telemetries[0].humidity < 30.0
        return False

    @property
    def is_online(self) -> bool:
        if self.telemetries:
            # Consideramos online si ha reportado telemetría en los últimos 30 segundos
            delta = datetime.utcnow() - self.telemetries[0].timestamp
            return delta.total_seconds() < 30
        return False

