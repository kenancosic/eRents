﻿using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.Service.PaymentService
{
	public interface IPaymentService
	{
		Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request);
		Task<PaymentResponse> GetPaymentStatusAsync(int paymentId);
	}
}