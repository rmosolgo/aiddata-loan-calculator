require 'sinatra'
require 'sinatra/reloader'
require 'json'


get '/test' do
	loan = {
		face_value: 1000,
		maturity: 10,
		grace_period: 2.5,
		interest_rate: 0.025,
		discount_rate: 0.1
	}

	lifecycle = calculate_grant_element loan

	JSON::dump(lifecycle)
end

get '/' do
	loan = params_to_loan(params)
	lifecycle = calculate_grant_element loan
	JSON::dump(lifecycle)	
end

def params_to_loan(params)
	loan = {
		value: params[:value].to_f,
		grace_period: params[:grace_period].to_f || 0.0,
		maturity: params[:maturity].to_f,
		interest_rate: (params[:interest_rate]  || default_interest_rate_for(params[:year])).to_f,
		discount_rate: (params[:discount_rate] || default_discount_rate_for(params[:year])).to_f ,
		include_lifecycle: params[:include_lifecycle] || false,
	}
end

def calculate_grant_element(loan)
	# loan is a hash with:
	# 	value
	# 	grace_period
	# 	maturity
	#
	# 	interest_rate
	#   discount_rate
	#
	#   


	# These loan terms are required: VALUE, GRACE PD, MATURITY
	unless (face_value = loan[:value]) > 0
		return { error: "No loan value provided"}
	end

	unless grace_period_in_years = loan[:grace_period]
		return { error: "No grace period provided"}
	end

	unless	(maturity_in_years = loan[:maturity]) > 0
		return { error: "No maturity provided"}
	end


	# These terms can have guesses provided
	interest_rate = loan[:interest_rate]
	
	if loan[:use_oecd_method]
		discount_rate = 0.1
	else
		discount_rate = loan[:discount_rate] 
	end


	disbursement_span_in_years = loan[:disbursement_span_in_years] || 1 # defaults to lump sum
	disbursements_per_year = loan[:disbursements_per_year] || 1 # defaults to lump sum

	repayments_per_year = loan[:repayments_per_year] || 2 # defaults to semi-annual
	repayment_plan = loan[:repayment_plan] || "EPP"

	# Begin calculations!
	grace_periods = grace_period_in_years*repayments_per_year.round
	repayment_periods = (maturity_in_years*(repayments_per_year)).round 

	loan_lifecycle = []
	previous_period = {}

	(repayment_periods + 1).times do |p|

		p += 0.0

		this_period = {
			index: (p),
			years: (p/repayments_per_year),
			factor: (p > 0 ? (previous_period[:factor]) * (1 + (discount_rate/repayments_per_year)) : 1 ).round(2) ,
			# previous_period: ( previous_period[:outstanding] ? "true" : "false" ) ,
		}
			

		if (p+1) <= disbursement_span_in_years * disbursements_per_year
			# p "Disburse!"
			this_period[:disbursement] = (disbursement_span_in_years/disbursements_per_year) * face_value 
		else 
			this_period[:disbursement] = 0
		end



		this_period[:outstanding] =  
			# what was already outstanding
			(previous_period[:outstanding] || 0) + 
			# plus interest on that 
			(previous_period[:outstanding] || 0 ) * (interest_rate/repayments_per_year) +
			# plus disbursements since last time
			(previous_period[:disbursement] || 0 ) -
			# minus whatever was paid last period
			(previous_period[:total_repayment] || 0 )

		if p != 0
			this_period[:interest_repayment] = (this_period[:outstanding] * (interest_rate/repayments_per_year))
		else 
			this_period[:interest_repayment] = 0
		end

		if p >= grace_periods 
			this_period[:principal_repayment] = face_value/(repayment_periods-grace_periods+1)
		else 
			this_period[:principal_repayment] = 0 
		end


		this_period[:total_repayment] = this_period[:interest_repayment] + this_period[:principal_repayment]

		this_period[:present_value_of_disbursement] = this_period[:disbursement]/this_period[:factor]
		this_period[:present_value_of_repayment] = this_period[:total_repayment]/this_period[:factor]

		loan_lifecycle.push(this_period)

		previous_period = this_period
	
	end

	pv_repayment = 0.0
	pv_disbursement = 0.0
	loan_lifecycle.each do |pd| 
		pv_disbursement += pd[:present_value_of_disbursement]
		pv_repayment += pd[:present_value_of_repayment]
	end

	result = {
		present_value_of_repayments: pv_repayment.round(2),
		present_value_of_disbursements: pv_disbursement.round(2),
		grant_element_value: (pv_disbursement - pv_repayment).round(2),
		grant_element_percent: ((pv_disbursement - pv_repayment)/pv_disbursement).round(4),
		interest_rate: interest_rate,
		discount_rate: discount_rate,
		maturity: maturity_in_years,
		grace_period: grace_period_in_years,
		repayments_per_year: repayments_per_year,
		
	}
	
	result[:lifecycle] = loan_lifecycle if loan[:include_lifecycle]


	return result

end


REPAYMENT_PLANS = [
	"EPP",
	"LUMP SUM"
	]

DISBURSEMENT_PLANS = [
	"LUMP SUM"
	]

def default_interest_rate_for(year)
	# Maintain this API
	0.05
end

DEFAULT_INTEREST_RATES = {
	1999 => 0
}

def default_discount_rate_for(year)
	# Maintain this API
	0.1
end

OECD_HISTORICAL_DISCOUNT_RATES = {
	1999 => 0.04
}