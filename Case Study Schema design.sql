-- The Service_Categories table acts as a centralized lookup for service types.
CREATE TABLE Service_Categories (
    service_id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    description TEXT
);

-- 1. User and Account Management

CREATE TABLE Users (
    user_id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    mobile_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    registration_dt TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    kyc_status VARCHAR(10) NOT NULL DEFAULT 'pending'
         CHECK (kyc_status IN ('pending','verified','failed')),
    referral_code VARCHAR(50),
    referred_by BIGINT,
    CONSTRAINT fk_referred_by FOREIGN KEY (referred_by) REFERENCES Users(user_id)
);

CREATE TABLE Bank_Accounts (
    account_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    ifsc_code VARCHAR(20) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    verification_status VARCHAR(10) NOT NULL DEFAULT 'pending'
         CHECK (verification_status IN ('pending','verified','failed')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bank_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Wallets (
    wallet_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Referral_Rewards (
    reward_id BIGSERIAL PRIMARY KEY,
    referrer_id BIGINT NOT NULL,
    referee_id BIGINT NOT NULL,
    reward_amount NUMERIC(10,2) NOT NULL,
    reward_type VARCHAR(50) NOT NULL,
    awarded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_referrer FOREIGN KEY (referrer_id)  REFERENCES Users(user_id),
    CONSTRAINT fk_referee FOREIGN KEY (referee_id) REFERENCES Users(user_id)
);

-- 2. Payment and UPI Transactions

CREATE TABLE UPI_Transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    payment_method VARCHAR(10) NOT NULL
         CHECK (payment_method IN ('UPI','Wallet')),
    status VARCHAR(10) NOT NULL 
		 CHECK (status IN ('pending','success','failed')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    reference_no VARCHAR(100),
    CONSTRAINT fk_sender FOREIGN KEY (sender_id) REFERENCES Users(user_id),
    CONSTRAINT fk_receiver FOREIGN KEY (receiver_id) REFERENCES Users(user_id)
);

-- 3. Bill Payments and Recharges
CREATE TABLE Bill_Payments (
    bill_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    service_id BIGINT,  
    category VARCHAR(50) NOT NULL,       
    sub_category VARCHAR(50) NOT NULL,    
    amount NUMERIC(15,2) NOT NULL,
    status VARCHAR(10) NOT NULL 
		CHECK (status IN ('pending','success','failed')),
    payment_method VARCHAR(50) NOT NULL,
    transaction_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    vendor_id BIGINT,  
    additional_info JSONB,
    CONSTRAINT fk_bill_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_bill_service FOREIGN KEY (service_id) REFERENCES Service_Categories(service_id),
    CONSTRAINT fk_bill_vendor FOREIGN KEY (vendor_id) REFERENCES Vendors(vendor_id)	
);

-- 4. Insurance

CREATE TABLE Insurance_Purchases (
    insurance_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    policy_number VARCHAR(100) NOT NULL,
    insurance_type VARCHAR(50) NOT NULL, 
    premium_amount NUMERIC(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(10) NOT NULL 
		CHECK (status IN ('active','expired','lapsed')),
    next_due_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    additional_details JSONB,
    CONSTRAINT fk_insurance_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Insurance_Premium_Payments (
    premium_payment_id BIGSERIAL PRIMARY KEY,
    insurance_id BIGINT NOT NULL,
    payment_amount NUMERIC(15,2) NOT NULL,
    payment_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(10) NOT NULL 
		CHECK (status IN ('pending','success','failed')),
    payment_method VARCHAR(50) NOT NULL,
    remarks VARCHAR(255),
    CONSTRAINT fk_premium_insurance FOREIGN KEY (insurance_id) REFERENCES Insurance_Purchases(insurance_id)
);

-- 5. Wealth and Investments

CREATE TABLE Investments (
    investment_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_type VARCHAR(50) NOT NULL,  
    product_sub_type VARCHAR(50),      
    investment_amount NUMERIC(15,2) NOT NULL,
    current_value NUMERIC(15,2),
    start_date DATE NOT NULL,
    maturity_date DATE,
    status VARCHAR(15) NOT NULL 
		CHECK (status IN ('active','matured','liquidated')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    additional_info JSONB,
    CONSTRAINT fk_investment_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- 6. Travel and Mobility
CREATE TABLE Travel_Bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    travel_mode VARCHAR(20) NOT NULL
         CHECK (travel_mode IN ('metro','flight','bus','train','hotel','cab','airport_cab','travel_activity','visa','travel_insurance')),
    vendor_id BIGINT,
    booking_details JSONB,
    amount NUMERIC(15,2) NOT NULL,
    status VARCHAR(15) NOT NULL CHECK (status IN ('pending','confirmed','cancelled')),
    booked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_travel_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
	CONSTRAINT fk_travel_vendor FOREIGN KEY (vendor_id) REFERENCES Vendors(vendor_id)
);

-- 7. E‑Commerce and Purchases

CREATE TABLE Purchase_Orders (
    purchase_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    service_id BIGINT, 
    purchase_category VARCHAR(50) NOT NULL, 
    item_details JSONB,
    amount NUMERIC(15,2) NOT NULL,
    payment_status VARCHAR(15) NOT NULL CHECK (payment_status IN ('pending','success','failed')),
    purchase_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_user FOREIGN KEY (user_id)
        REFERENCES Users(user_id),
    CONSTRAINT fk_purchase_service FOREIGN KEY (service_id)
        REFERENCES Service_Categories(service_id)
);

-- 8. Supporting Lookup Tables

CREATE TABLE Vendors (
    vendor_id BIGSERIAL PRIMARY KEY,
    vendor_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,       
    contact_details JSONB,
    website VARCHAR(255)
);


